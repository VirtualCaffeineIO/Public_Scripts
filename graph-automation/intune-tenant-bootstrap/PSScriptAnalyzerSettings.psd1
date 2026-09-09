@{
    Severity = @('Error', 'Warning')

    ExcludeRules = @(
        # This is an operator-facing console tool. Coloured status lines are the
        # product, not incidental output, and the run is captured by transcript
        # and by the CSV/JSON summary rather than by the pipeline.
        'PSAvoidUsingWriteHost'

        # Script parameters are consumed inside functions declared in the same
        # script scope. The rule does not follow that and reports every one.
        'PSReviewUnusedParameter'
    )
}
