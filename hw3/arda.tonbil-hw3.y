%{
#ifdef YYDEBUG
  yydebug = 1;
#endif
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>

extern int yylex();
extern int yylineno;

#define MAX_SYMBOLS 128
#define MAX_ERRORS 256

typedef struct Identifier {
    char* name;        
    char* type;         
    int line;             
    bool assigned;         
    bool used;            
    bool value;           // Current value (for circuit evaluation)
} Identifier;

typedef struct Error {
    int line;
    char message[256];
} Error;

Identifier symboltable[MAX_SYMBOLS];
int identifierNumber = 0;
int errorExists = 0;

Error errorList[MAX_ERRORS];
int errorCount = 0;

bool circuitEvaluated = false; // To ensure circuit evaluation only prints once

void addIdentifier(Identifier* table, char* name, char* type, int line){
    table[identifierNumber].name = strdup(name);  
    table[identifierNumber].type = strdup(type);  
    table[identifierNumber].line = line;
    table[identifierNumber].assigned = false;  
    table[identifierNumber].used = false;      
    table[identifierNumber].value = false;     
    identifierNumber++;
}

int findIdentifier(Identifier* table, char* name){
    for (int i = 0; i < identifierNumber; i++){
        if (strcmp(table[i].name, name) == 0) return i;
    }
    return -1;
}

void checkUnusedIdentifiers(Identifier* table){
    for (int i = 0; i < identifierNumber; i++){
        if (((strcmp(table[i].type, "input") == 0 || strcmp(table[i].type, "node") == 0)) && table[i].used == false) {
            snprintf(errorList[errorCount].message, sizeof(errorList[errorCount].message),
                     "ERROR at line %d: %s is not used.", table[i].line, table[i].name);
            errorList[errorCount].line = table[i].line;
            errorCount++;
            errorExists = 1;
        }
    }
}

void checkUnassignedIdentifiers(Identifier* table){
    for (int i = 0; i < identifierNumber; i++){
        if (((strcmp(table[i].type, "output") == 0 || strcmp(table[i].type, "node") == 0)) && table[i].assigned == false) {
            snprintf(errorList[errorCount].message, sizeof(errorList[errorCount].message),
                     "ERROR at line %d: %s is not assigned.", table[i].line, table[i].name);
            errorList[errorCount].line = table[i].line;
            errorCount++;
            errorExists = 1;
        }
    }
}

void checkUnassignedInputs(Identifier* table){
    for (int i = 0; i < identifierNumber; i++){
        if(strcmp(table[i].type, "input") == 0 && table[i].assigned == false){
            snprintf(errorList[errorCount].message, sizeof(errorList[errorCount].message),
                     "ERROR at line %d: %s is not assigned.", yylineno, table[i].name);
            errorList[errorCount].line = yylineno;
            errorCount++;
            errorExists = 1;
        }
    }
}

void sortErrorsByLine(Error* errors, int count) {
    for (int i = 0; i < count - 1; i++) {
        for (int j = 0; j < count - i - 1; j++) {
            if (errors[j].line > errors[j + 1].line) {
                Error temp = errors[j];
                errors[j] = errors[j + 1];
                errors[j + 1] = temp;
            }
        }
    }
}

void evaluateCircuit() {
    if (!circuitEvaluated) { // Print results only once
        circuitEvaluated = true;
        for (int i = 0; i < identifierNumber; i++) {
            if (strcmp(symboltable[i].type, "output") == 0) {
                printf("%s=%s\n", symboltable[i].name, symboltable[i].value ? "true" : "false");
            }
        }
    }
}

void setInputValue(char* name, bool value) {
    int idx = findIdentifier(symboltable, name);
    if (idx >= 0) {
        symboltable[idx].value = value;
        symboltable[idx].assigned = true;
    }
}

void yyerror(const char *msg) { return; }
%}

%union {
    struct Identifier_Info{
        char *string;  // For token strings
        int valueNum;  // For integer values (if needed in the future)
    } Identifier_Info;
}

%token <Identifier_Info> tIDENTIFIER 
%token <string> tINPUT tOUTPUT tNODE
%token tEVALUATE tOR tAND tXOR tNOT tASSIGNMENT tCOMMA tLPR tRPR tTRUE tFALSE
%left tOR tXOR
%left tAND
%precedence tNOT
%start program

%%

program : lcd;

lcd : 
    | declarations circuitDesign evaluations{
        checkUnusedIdentifiers(symboltable);
        checkUnassignedIdentifiers(symboltable);
    }
;

declarations : declaration 
             | declaration declarations
;

declaration : input 
            | output 
            | node
;

input : tINPUT identifierListInput
;

output : tOUTPUT identifierListOutput
;

node : tNODE identifierListNode
;

identifierListInput : tIDENTIFIER {
                        int check = findIdentifier(symboltable, ($1).string);
                        if(check >= 0) {
                            snprintf(errorList[errorCount].message, sizeof(errorList[errorCount].message),
                                     "ERROR at line %d: %s is already declared as a(n) %s.", ($1).valueNum, ($1).string, symboltable[check].type);
                            errorList[errorCount].line = ($1).valueNum;
                            errorCount++;
                            errorExists = 1;
                        }
                        else addIdentifier(symboltable, ($1).string, "input", ($1).valueNum);
                    }
                    | tIDENTIFIER tCOMMA identifierListInput {
                        int check = findIdentifier(symboltable, ($1).string);
                        if(check >= 0) {
                            snprintf(errorList[errorCount].message, sizeof(errorList[errorCount].message),
                                     "ERROR at line %d: %s is already declared as a(n) %s.", ($1).valueNum, ($1).string, symboltable[check].type);
                            errorList[errorCount].line = ($1).valueNum;
                            errorCount++;
                            errorExists = 1;
                        }
                        else addIdentifier(symboltable, ($1).string, "input", ($1).valueNum);
                    }

identifierListOutput : tIDENTIFIER {
                        int check = findIdentifier(symboltable, ($1).string);
                        if(check >= 0) {
                            snprintf(errorList[errorCount].message, sizeof(errorList[errorCount].message),
                                     "ERROR at line %d: %s is already declared as a(n) %s.", ($1).valueNum, ($1).string, symboltable[check].type);
                            errorList[errorCount].line = ($1).valueNum;
                            errorCount++;
                            errorExists = 1;
                        }
                        else addIdentifier(symboltable, ($1).string, "output", ($1).valueNum);
                     }
                     | tIDENTIFIER tCOMMA identifierListOutput {
                        int check = findIdentifier(symboltable, ($1).string);
                        if(check >= 0) {
                            snprintf(errorList[errorCount].message, sizeof(errorList[errorCount].message),
                                     "ERROR at line %d: %s is already declared as a(n) %s.", ($1).valueNum, ($1).string, symboltable[check].type);
                            errorList[errorCount].line = ($1).valueNum;
                            errorCount++;
                            errorExists = 1;
                        }
                        else addIdentifier(symboltable, ($1).string, "output", ($1).valueNum);
                     }
;

identifierListNode : tIDENTIFIER {
                        int check = findIdentifier(symboltable, ($1).string);
                        if(check >= 0) {
                            snprintf(errorList[errorCount].message, sizeof(errorList[errorCount].message),
                                     "ERROR at line %d: %s is already declared as a(n) %s.", ($1).valueNum, ($1).string, symboltable[check].type);
                            errorList[errorCount].line = ($1).valueNum;
                            errorCount++;
                            errorExists = 1;
                        }
                        else addIdentifier(symboltable, ($1).string, "node", ($1).valueNum);
                    }
                    | tIDENTIFIER tCOMMA identifierListNode {
                        int check = findIdentifier(symboltable, ($1).string);
                        if(check >= 0) {
                            snprintf(errorList[errorCount].message, sizeof(errorList[errorCount].message),
                                     "ERROR at line %d: %s is already declared as a(n) %s.", ($1).valueNum, ($1).string, symboltable[check].type);
                            errorList[errorCount].line = ($1).valueNum;
                            errorCount++;
                            errorExists = 1;
                        }
                        else addIdentifier(symboltable, ($1).string, "node", ($1).valueNum);
                    }

circuitDesign : assignment 
              | assignment circuitDesign
;

assignment : tIDENTIFIER tASSIGNMENT expression {
    int check = findIdentifier(symboltable, ($1).string);
    if (check < 0) {
        snprintf(errorList[errorCount].message, sizeof(errorList[errorCount].message),
                 "ERROR at line %d: %s is undeclared.", ($1).valueNum, ($1).string);
        errorList[errorCount].line = ($1).valueNum;
        errorCount++;
        errorExists = 1;
    }
    else if (strcmp(symboltable[check].type, "input") == 0) {
        snprintf(errorList[errorCount].message, sizeof(errorList[errorCount].message),
                 "ERROR at line %d: %s is already assigned.", ($1).valueNum, ($1).string);
        errorList[errorCount].line = ($1).valueNum;
        errorCount++;
        errorExists = 1;
    }
    else if (symboltable[check].assigned == true) {
        snprintf(errorList[errorCount].message, sizeof(errorList[errorCount].message),
                 "ERROR at line %d: %s is already assigned.", ($1).valueNum, ($1).string);
        errorList[errorCount].line = ($1).valueNum;
        errorCount++;
        errorExists = 1;
    }
    else symboltable[check].assigned = true;
}
;

expression : tNOT expression 
           | tLPR expression tRPR
           | tIDENTIFIER {
                int check = findIdentifier(symboltable, ($1).string);
                if (check < 0) {
                    snprintf(errorList[errorCount].message, sizeof(errorList[errorCount].message),
                             "ERROR at line %d: %s is undeclared.", yylineno, ($1).string);
                    errorList[errorCount].line = yylineno;
                    errorCount++;
                    errorExists = 1;
                }
                else {
                    symboltable[check].used = true;
                }
           }
           | expression tAND expression 
           | expression tOR expression
           | expression tXOR expression 
           | tTRUE 
           | tFALSE
;

evaluations : evaluation 
            | evaluation evaluations
;

evaluation : tEVALUATE tIDENTIFIER tLPR evaluationAssignmentList tRPR {
                checkUnassignedInputs(symboltable);
                for (int i = 0; i < identifierNumber; i++){
                    if (strcmp(symboltable[i].type, "input") == 0) symboltable[i].assigned = false;
                }
                evaluateCircuit();
            }
;

evaluationAssignmentList : evaluationAssignment 
                         | evaluationAssignment tCOMMA evaluationAssignmentList
;

evaluationAssignment : tIDENTIFIER tASSIGNMENT tTRUE {
                            setInputValue(($1).string, true);
                     }
                     | tIDENTIFIER tASSIGNMENT tFALSE {
                            setInputValue(($1).string, false);
                     }
;

%%

int main () 
{
    if (yyparse())
    {
        printf("ERROR\n");
        return 1;
    } 
    else 
    {
        // Sort and print errors
        sortErrorsByLine(errorList, errorCount);
        for (int i = 0; i < errorCount; i++) {
            printf("%s\n", errorList[i].message);
        }

        if (errorExists == 0){  // Circuit evaluation
            evaluateCircuit();
        }
        return 0;
    }
}