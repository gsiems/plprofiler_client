# plprofiler_client

A [plprofiler](https://github.com/bigsql/plprofiler) client written in plsql and shell.

The original goal was to use plprofiler in conjunction with
[pgTap](https://github.com/theory/pgtap) in order to both measure performance and
test coverage.

## The problem

1. Initially, this needed to be run on a RedHat box where it was found that the
plprofiler client didn't work due to some files missing from the system python
(and there was no interest in maintaining a separate python install just to run
one CLI app).

2. The output from the plprofiler client wasn't very useful for measuring pgTap
test coverage.

## The solution

The chosen solution was to create database functions from queries extracted from
the python client, add a couple of report generator functions (one for performance
and one for test coverage), and finally add some shell (bash actually) scripting to
make the functions easier to use for testing.

## Usage

Load the profiler_client schema into the database:

    ```
    cd profile_client
    psql ... -f schema.sql
    ```

then include the client.sh script in the testing (bash) script:

    ```
    #!/usr/bin/env bash

    # ... whatever initialization is needed

    source client.sh

    init_plprofiler

    # ... the testing to profile

    generate_plprofiler_reports

    ```

## Report output

### Coverage report

The coverage report consists of two sections, a summary showing counts and
percentages by schema and a details section that lists all functions and
procedures and whether they were executed or not.

![Coverage report](doc/coverage.png)

### Profiler report

The profiler report contains a hot spots section that lists the
functions/procedures that have either the highest total self-time or the
highest average self-time as well as a details section that lists the profile
data that was gathered for all functions and procedures.

![Profile report](doc/profile.png)

Clicking on the details link for any given function/procedure expands the
profile data to show the line-by-line profile data for that function/procedure.

![Profile detail](doc/profile_detail.png)

## Limitations

This is subject to the same limitations as plprofiler... namely that plprofiler
only works for ```LANGUAGE plpgsql``` functions/procedures.
