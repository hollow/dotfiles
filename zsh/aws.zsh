# https://aws.amazon.com/de/cli/
aws-each-region() {
    local regions=(
        $(aws ec2 describe-regions | jq -r '.Regions[].RegionName')
    )

    for region in ${regions}; do
        echo "\n>>> ${region}"
        aws --region "${region}" "$@"
    done
}
