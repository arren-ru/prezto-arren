#
# Terraform HTTP-backend credentials from Vault.
#
# Logs in to Vault with userpass, caches the token, exchanges it for an OIDC JWT
# and exports the pair terraform expects:
#
#   TF_HTTP_USERNAME=jwt
#   TF_HTTP_PASSWORD=<jwt>
#
# Both tokens are cached in $HOME with mode 0600. A cache file's *mtime is its
# refresh deadline*, derived from the TTL Vault reported, so the module never
# hands terraform a token it knows has expired and the steady-state cost of a
# new shell is two stat(2) calls and no forks.
#
# Requires: VAULT_ADDR, VAULT_USERNAME, VAULT_PASSWORD.
#
# Configuration:
#   zstyle ':prezto:module:terraform-vault-auth' oidc-role 'terraform-backend'
#   zstyle ':prezto:module:terraform-vault-auth' timeout   2 10   # connect, total
#   zstyle ':prezto:module:terraform-vault-auth' quiet     'yes'
#
# To force a full re-login: rm -f ~/.terraform-vault-token ~/.terraform-jwt-token
#

(( $+commands[curl] && $+commands[jq] )) || return 1

zmodload zsh/datetime            # EPOCHSECONDS, strftime
zmodload -F zsh/stat b:zstat     # zstat, without shadowing stat(1)
zmodload -F zsh/system p:sysparams

local __tva_style=':prezto:module:terraform-vault-auth'
local __tva_vault_file=$HOME/.terraform-vault-token
local __tva_jwt_file=$HOME/.terraform-jwt-token
local __tva_role __tva_fallback_ttl=3600 __tva_rc __tva_logged_in=0
local -a __tva_curl __tva_timeout
local __tva_err __tva_warn __tva_token __tva_ttl   # __tva_fetch output

zstyle -s $__tva_style oidc-role __tva_role || __tva_role='terraform-backend'
zstyle -a $__tva_style timeout   __tva_timeout || __tva_timeout=(2 10)

# Fail fast: an unreachable or black-holed VAULT_ADDR must never hang a shell.
# No --retry; a retry loop multiplies the worst case by the attempt count.
__tva_curl=(
    --silent --fail-with-body
    --connect-timeout $__tva_timeout[1]
    --max-time        $__tva_timeout[2]
    --header 'Content-Type: application/json'
)

# One filter for all three endpoints. The trailing "ok" is a sentinel: if it
# does not come back, stdout was not a Vault JSON document (empty reply, proxy
# error page, jq missing) and the response must not be trusted.
local __tva_jq='
    def nul: [0] | implode;   # separator that cannot occur inside a Vault string
    (.errors   // [] | join("; ")),
    (.warnings // [] | join("; ")),
    (.auth.client_token    // .data.token // ""),
    ((.auth.lease_duration // .data.ttl   // 0) | tostring),
    "ok"
    | (. + nul)'

__tva_say() {
    zstyle -t $__tva_style quiet || print -u2 -r -- "terraform-vault-auth: $1"
}

__tva_warn_of() {
    print -u2 -r -- "terraform-vault-auth: warning: $1"
}

__tva_fail() {
    print -u2 -r -- "terraform-vault-auth: $1"
}

# Is the cached token still inside its refresh window?  Zero-byte files are
# never fresh, so a truncated write can't wedge the cache until it ages out.
__tva_fresh() {
    local -a st
    [[ -s $1 ]] || return 1
    zstat -A st +mtime $1 2>/dev/null || return 1
    (( st[1] > EPOCHSECONDS ))
}

# Write atomically at 0600, stamping the refresh deadline onto the mtime.
# The temp name uses sysparams[pid], not $$: zsh keeps $$ at the *parent* pid
# inside subshells, so several shells starting at once would collide on it.
__tva_store() {
    local file=$1 token=$2 ttl=$3 tmp=$1.${sysparams[pid]:-$$}
    (( ttl > 0 )) || ttl=$__tva_fallback_ttl

    (umask 077; print -rn -- "$token" > $tmp) || return 1
    # Refresh with ~20% of the lease left, so terraform still gets a live token
    # even if the shell was started right on the boundary.
    touch -t "$(strftime '%Y%m%d%H%M.%S' $(( EPOCHSECONDS + ttl * 4 / 5 )))" $tmp &&
        mv -f $tmp $file && return 0

    rm -f $tmp
    return 1
}

# Call Vault. Sets __tva_token/__tva_ttl/__tva_warn on success.
#   0 = ok   1 = transport failure (retryable)   2 = Vault refused (terminal)
__tva_fetch() {
    local body rc detail err warn token ttl ok
    __tva_err= __tva_warn= __tva_token= __tva_ttl=0

    body=$(curl "${__tva_curl[@]}" "$@" 2>/dev/null)
    rc=$?

    {
        read -rd '' err
        read -rd '' warn
        read -rd '' token
        read -rd '' ttl
        read -rd '' ok
    } < <(print -r -- "$body" | jq -rc "$__tva_jq" 2>/dev/null)

    if [[ $ok != ok ]]; then
        case $rc in
            6)     detail='could not resolve host' ;;
            7)     detail='connection refused' ;;
            28)    detail="no response within ${__tva_timeout[2]}s" ;;
            35|60) detail='TLS handshake failed' ;;
            0)     detail='response was not a Vault JSON document' ;;
            *)     detail="curl exit $rc" ;;
        esac
        __tva_err="$VAULT_ADDR: $detail"
        return 1
    fi

    __tva_warn=$warn
    [[ -z $err ]] || { __tva_err=$err; return 2 }
    (( rc == 0 )) || { __tva_err="request failed (curl exit $rc)"; return 1 }
    [[ -n $token ]] || { __tva_err='response carried no token'; return 2 }

    __tva_token=$token
    [[ $ttl == <-> ]] && __tva_ttl=$ttl
    return 0
}

# Same, with the cached Vault token as credentials. The token goes in through a
# curl config on stdin rather than argv, where ps(1) would expose it.
__tva_fetch_authed() {
    [[ -s $__tva_vault_file ]] || { __tva_err='no cached vault token'; return 2 }
    __tva_fetch --config - "$@" <<<"header = \"X-Vault-Token: $(<$__tva_vault_file)\""
}

__tva_login() {
    local user
    if [[ -z $VAULT_ADDR || -z $VAULT_USERNAME || -z $VAULT_PASSWORD ]]; then
        __tva_err='VAULT_ADDR, VAULT_USERNAME and VAULT_PASSWORD must be set'
        return 2
    fi
    user=$(jq -rn --arg u "$VAULT_USERNAME" '$u | @uri')

    # Password on stdin, not in -d: argv is world-readable through ps(1).
    # jq builds the body so quotes and backslashes can't break the JSON.
    __tva_fetch --request POST --data @- \
        "$VAULT_ADDR/v1/auth/userpass/login/$user" \
        <<<"$(jq -nc --arg p "$VAULT_PASSWORD" '{password: $p}')" || return $?

    __tva_store $__tva_vault_file "$__tva_token" $__tva_ttl || {
        __tva_err="cannot write $__tva_vault_file"
        return 2
    }
    __tva_logged_in=1

    __tva_say "logged in to Vault as $VAULT_USERNAME"
}

# A renewal that fails is routine -- the token simply expired -- so it stays
# silent and lets the caller fall back to a full login. Only the login gets to
# complain.
__tva_renew() {
    __tva_fetch_authed --request POST "$VAULT_ADDR/v1/auth/token/renew-self" || return $?
    __tva_store $__tva_vault_file "$__tva_token" $__tva_ttl || return 2
    __tva_say 'renewed Vault token'
}

__tva_vault_token() {
    __tva_fresh $__tva_vault_file && return 0
    [[ -s $__tva_vault_file ]] && __tva_renew && return 0
    __tva_login
}

__tva_jwt() {
    local rc
    __tva_fresh $__tva_jwt_file && return 0

    __tva_fetch_authed --request GET "$VAULT_ADDR/v1/identity/oidc/token/$__tva_role"
    rc=$?

    # Vault refused the cached token: it died between the two calls. Log in once
    # and retry -- but not if this run already logged in, or the same rejection
    # would loop.
    if (( rc == 2 && ! __tva_logged_in )); then
        __tva_login || return $?
        __tva_fetch_authed --request GET "$VAULT_ADDR/v1/identity/oidc/token/$__tva_role"
        rc=$?
    fi
    (( rc == 0 )) || return $rc

    __tva_store $__tva_jwt_file "$__tva_token" $__tva_ttl || {
        __tva_err="cannot write $__tva_jwt_file"
        return 2
    }
    __tva_say "refreshed terraform backend token (role $__tva_role)"
}

__tva_main() {
    if [[ -z $VAULT_ADDR ]]; then
        __tva_fail 'VAULT_ADDR is not set'
        return 1
    fi

    __tva_vault_token || { __tva_fail "$__tva_err"; return 1 }
    [[ -z $__tva_warn ]] || __tva_warn_of "$__tva_warn"

    __tva_jwt || { __tva_fail "$__tva_err"; return 1 }
    [[ -z $__tva_warn ]] || __tva_warn_of "$__tva_warn"

    export TF_HTTP_USERNAME=jwt
    export TF_HTTP_PASSWORD="$(<$__tva_jwt_file)"
}

__tva_main
__tva_rc=$?

unfunction __tva_say __tva_warn_of __tva_fail __tva_fresh __tva_store \
    __tva_fetch __tva_fetch_authed __tva_login __tva_renew __tva_vault_token \
    __tva_jwt __tva_main

return $__tva_rc
