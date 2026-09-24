BEGIN { FS = "[= ]"; records = 0; completed = 0; malformed = 0 }
/^Branches=/ {
    if ($0 !~ /^Branches=[0-9]+ Correct=[0-9]+$/) malformed = 1
    else { records++; branches = $2 + 0; correct = $4 + 0 }
}
/^Passed!$/ { completed++ }
/^Failed[.!: ]/ { malformed = 1 }
END {
    if (!malformed && records == 1 && completed == 1 &&
        branches > 0 && branches <= 4294967295 &&
        correct <= branches && 2 * correct >= branches) {
        print "Passed!"
        exit 0
    }
    print "expected output: Accuracy >= 50%"
    print "actual output: Accuracy=" (branches ? 100 * correct / branches : 0) "%"
    exit 1
}
