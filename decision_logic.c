// decision_logic.c
// Test function for MC/DC coverage: (a && b) || c

#include <stdbool.h>
bool decision(bool a, bool b, bool c) { return (a && b) || c; }
