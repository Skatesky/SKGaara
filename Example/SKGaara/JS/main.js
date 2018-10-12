fixInstanceMethodReplace('SKViewController', 'fixMethod', function(instance, originInvocation, originArguments) {
    runInstanceWith1Paramter(instance, 'print:', null);
    runInstanceWith2Paramters(instance, 'sum:b:', 1, 2);
});
