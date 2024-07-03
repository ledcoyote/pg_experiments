#!/usr/bin/expect
set timeout -1
spawn ./run_experiment.sh
expect "postgres: "
send -- "password\r"
expect "Password: "
send -- "password\r"
expect "Password: "
send -- "password\r"
expect eof

