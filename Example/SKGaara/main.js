fixInstanceMethodReplace('SKViewController', 'fixMethod', function(instance, originInvocation, originArguments) {
    runInstanceWith1Paramter(instance, 'print:');
    runInstanceWith2Paramters(instance, 'sum:b:');
});
