# Task 6 must finish successfully AND validate real counter values.
BEGIN { bad = 0; counts = 0; accuracies = 0; validations = 0; passes = 0 }
/^Branches=/ {
    counts++
    if ($0 !~ /^Branches=[0-9]+ Correct=[0-9]+$/) { bad = 1; next }
    split($0, fields, /[ =]/)
    branches = fields[2] + 0
    correct = fields[4] + 0
}
/^Accuracy=/ {
    accuracies++
    if ($0 !~ /^Accuracy=[0-9]+([.][0-9]+)?%$/) { bad = 1; next }
    split($0, fields, /[=%]/)
    accuracy = fields[2] + 0
}
/^CountersValidated=/ {
    validations++
    if ($0 != "CountersValidated=1") bad = 1
}
/^Passed!$/ { passes++ }
/^Failed/ { bad = 1 }
END {
    if (counts != 1 || accuracies != 1 || validations != 1 || passes != 1) bad = 1
    if (branches <= 0 || branches > 4294967295 || correct < 0 || correct > branches) bad = 1
    if (accuracy < 0 || accuracy > 100) bad = 1
    if (branches > 0) {
        measured = 100 * correct / branches
        delta = accuracy - measured
        if (delta < 0) delta = -delta
        if (delta > 0.00000051 || measured <= 30) bad = 1
    }
    if (!bad) {
        print "Passed!"
        exit 0
    }
    print "expected output: completed run, verified counters, Accuracy > 30%"
    print "actual output: Accuracy=" accuracy "%"
    exit 1
}
