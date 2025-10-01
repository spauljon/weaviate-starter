local_dir=$( cd "$(dirname "$0")/.." >/dev/null 2>&1 || exit ; pwd -P )
# shellcheck disable=SC2034
compose_dir=${local_dir}/compose

trap '{ popd ; }' EXIT

pushd "${local_dir}" || exit
