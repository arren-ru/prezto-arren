local vault_token_path=$HOME/.terraform-vault-token
local terraform_token_path=$HOME/.terraform-jwt-token

readonly curl_api_args=(-sS --fail-with-body --retry 10 --retry-delay 5 -H 'Content-Type: application/json')

__vault_login_userpass() {
    local err warn token
    {
        read -rd '' err
        read -rd '' warn
        read -rd '' token
    } < <(
        curl -d "{\"password\": \"$VAULT_PASSWORD\"}" "${curl_api_args[@]}" \
            -X POST "${VAULT_ADDR}/v1/auth/userpass/login/$VAULT_USERNAME" |
            jq -rc '(.errors//[]|join(" ")), (.warnings//[]|join(" ")), .auth.client_token//"" | (.+"\u0000")'
    )

    [[ -z $warn ]] || echo >&2 "$0: warning: $warn"
    [[ -z $err ]] || {
        echo >&2 "$0: error: $err"
        return 2
    }

    echo >&2 "Logged into vault"
    rm -f $vault_token_path
    echo >$vault_token_path -n "$token"
}

__vault_token_renew() {
    [[ -f $vault_token_path ]] || return 1
    [[ -n $(find $vault_token_path -type f -mtime +5) ]] || return 0

    local err warn token
    {
        read -rd '' err
        read -rd '' warn
        read -rd '' token
    } < <(
        curl "${curl_api_args[@]}" -H "X-Vault-Token: $(cat $vault_token_path)" \
            -X POST "${VAULT_ADDR:?}/v1/auth/token/renew-self" |
            jq -rc '(.errors//[]|join(" ")), (.warnings//[]|join(" ")), .auth.client_token//"" | (.+"\u0000")'
    )

    [[ -z $warn ]] || echo >&2 "$0: warning: $warn"
    [[ -z $err ]] || {
        echo >&2 "$0: error: $err"
        return 2
    }

    echo >&2 "Vault token refreshed"
    rm -f $vault_token_path
    echo >$vault_token_path -n "$token"
}

__terraform_token_renew() {
    [[ ! -f $terraform_token_path || -n $(find $terraform_token_path -type f -mtime +5) ]] || return 0

    local err warn token
    {
        read -rd '' err
        read -rd '' warn
        read -rd '' token
    } < <(
        curl "${curl_api_args[@]}" -H "X-Vault-Token: $(cat $vault_token_path)" \
            -X GET "${VAULT_ADDR:?}/v1/identity/oidc/token/terraform-backend" |
            jq -rc '(.errors//[]|join(" ")), (.warnings//[]|join(" ")), .data.token//"" | (.+"\u0000")'
    )

    [[ -z $warn ]] || echo >&2 "$0: warning: $warn"
    [[ -z $err ]] || {
        echo >&2 "$0: error: $err"
        return 2
    }

    echo >&2 "Terraform token refreshed"
    rm -f $terraform_token_path
    echo >$terraform_token_path -n "$token"
}

__vault_token_renew || __vault_login_userpass || return 1
__terraform_token_renew || return 1
export TF_HTTP_USERNAME=jwt
export TF_HTTP_PASSWORD=$(cat $terraform_token_path)

unfunction __vault_token_renew __vault_login_userpass __terraform_token_renew
