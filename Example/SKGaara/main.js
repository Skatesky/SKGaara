fixInstanceMethodReplace('SKViewController', 'fixMethod', function(instance, originInvocation, originArguments) {
    runInstanceWith1Paramter(instance, 'print:', 'Hello Native!');
});
