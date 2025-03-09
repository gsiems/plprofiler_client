#!/usr/bin/env bash

function init_plprofiler() {

    if [[ -z ${usr} ]]; then
        if [[ -n ${PGUSER} ]]; then
            usr="${PGUSER}"
        else
            usr="${USER}"
        fi
    fi
    if [[ -z ${db} ]]; then
        if [[ -n ${PGDATABASE} ]]; then
            db="${PGDATABASE}"
        else
            db="${USER}"
        fi
    fi
    if [[ -z ${port} ]]; then
        if [[ -n ${PGPORT} ]]; then
            port=${PGPORT}
        else
            port=5432
        fi
    fi

    if [[ -z ${profileName} ]]; then
        profileName=$(mktemp --dry-run Test_XXXXXXXX)
    fi

    if [[ -z ${profileFile} ]]; then
        profileFile="${profileName}_profile.html"
    fi

    if [[ -z ${coveredFile} ]]; then
        coveredFile="${profileName}_coverage.html"
    fi

    ####
    bd=$(dirname "$0")
    pushd "${bd}/plprofiler_client" || exit 66 # EX_NOINPUT
    psql -U "${usr}" -d "${db}" -p "${port}" -f schema.sql
    popd || exit 66 # EX_NOINPUT
    cmd="select plprofiler_client.init_profile ( a_name => '${profileName}' ) ;"

    echo "${cmd}" | psql -U "${usr}" -d "${db}" -p "${port}" -f - >/dev/null
}

######################################################

function generate_plprofiler_reports() {

    echo "# Generating the plprofiler reports"
    cmd="
select plprofiler_client.save_dataset_from_shared ( a_opt_name => '${profileName}', a_overwrite => true ) ;

select plprofiler_client.disable_monitor () ;

select plprofiler_client.reset_shared () ;
"
    echo "${cmd}" | psql -U "${usr}" -d "${db}" -p "${port}" -f - >/dev/null

    # Generate the profiler report
    echo "## Creating ${profileFile}"

    cmd="select plprofiler_client.generate_profiler_report ( a_name => '${profileName}', a_max_rank => 5 ) ;"

    echo "${cmd}" | psql -X -U "${usr}" -d "${db}" -p "${port}" -q -t -A >"${profileFile}"

    # Generate the coverage report
    echo "## Creating ${coveredFile}"

    cmd="select plprofiler_client.generate_coverage_report ( a_name => '${profileName}' ) ;"

    echo "${cmd}" | psql -X -U "${usr}" -d "${db}" -p "${port}" -q -t -A >"${coveredFile}"

    echo ""

    # Delete the profileName profile
    cmd="select plprofiler_client.delete_dataset ( a_opt_name => '${profileName}' ) ;"
    echo "${cmd}" | psql -U "${usr}" -d "${db}" -p "${port}" -f - >/dev/null
}
