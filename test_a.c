// test_a.c
// Test driver for MC/DC coverage of decision function

#include <stdbool.h>
#include <stdio.h>

// External declaration of the function under test
extern bool decision(bool a, bool b, bool c);

int main(void)
{
    // Test cases designed to achieve full MC/DC coverage for (a && b) || c
    // Each condition must independently affect the outcome

    // For MC/DC of (a && b) || c, we need test pairs where:
    // - Condition 'a' changes outcome:
    //   T: (T,T,F)->T vs F: (F,T,F)->F  [a flips, b=T, c=F]
    printf("Test 1: decision(true, true, false) = %d\n", decision(true, true, false));
    printf("Test 2: decision(false, true, false) = %d\n", decision(false, true, false));

    // - Condition 'b' changes outcome:
    //   T: (T,T,F)->T vs F: (T,F,F)->F  [b flips, a=T, c=F]
    printf("Test 3: decision(true, false, false) = %d\n", decision(true, false, false));
    // Already have (T,T,F) from test 1

    // - Condition 'c' changes outcome:
    //   T: (F,F,T)->T vs F: (F,F,F)->F  [c flips, a=F, b=F]
    printf("Test 4: decision(false, false, true) = %d\n", decision(false, false, true));
    printf("Test 5: decision(false, false, false) = %d\n", decision(false, false, false));

    return 0;
}
