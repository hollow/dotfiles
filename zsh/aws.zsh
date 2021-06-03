# https://aws.amazon.com/de/cli/
_brew_install awscli

aws-each-region() {
    local regions=(
        $(aws ec2 describe-regions | jq -r '.Regions[].RegionName')
    )

    for region in ${regions}; do
        echo "\n>>> ${region}"
        aws --region "${region}" "$@"
    done
}
