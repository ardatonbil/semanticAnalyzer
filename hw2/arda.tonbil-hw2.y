%{
#include <stdio.h>
#include <stdlib.h>

extern void yyerror (char const *s){}
extern int yylex(void);

%}

%token tINPUT tOUTPUT tNODE tEVALUATE tIDENTIFIER tAND tOR tXOR tNOT tTRUE tFALSE tLPR tRPR tASSIGNMENT tCOMMA

%left tOR tXOR
%left tAND
%right tNOT

%left tASSIGNMENT

%%

main_structure: declarations circuit evaluation | /* empty */ ;



declarations: 
    declarations tINPUT identifier_list_declaration | 
    declarations tOUTPUT identifier_list_declaration | 
    declarations tNODE identifier_list_declaration | 
    tINPUT identifier_list_declaration | 
    tOUTPUT identifier_list_declaration | 
    tNODE identifier_list_declaration;

identifier_list_declaration: tIDENTIFIER | tIDENTIFIER tCOMMA identifier_list_declaration;




circuit: tIDENTIFIER tASSIGNMENT logic_expression circuit | tIDENTIFIER tASSIGNMENT logic_expression;

logic_expression: 
    tIDENTIFIER | 
    tTRUE | 
    tFALSE | 
    tNOT logic_expression | 
    logic_expression tAND logic_expression | 
    logic_expression tOR logic_expression | 
    logic_expression tXOR logic_expression | 
    tLPR logic_expression tRPR;


evaluation: tEVALUATE tIDENTIFIER tLPR identifier_list_evaluate tRPR evaluation | tEVALUATE tIDENTIFIER tLPR identifier_list_evaluate tRPR; 


identifier_list_evaluate: 
    tIDENTIFIER tASSIGNMENT tTRUE | tIDENTIFIER tASSIGNMENT tFALSE | 
    tIDENTIFIER tASSIGNMENT tTRUE tCOMMA identifier_list_evaluate | tIDENTIFIER tASSIGNMENT tFALSE tCOMMA identifier_list_evaluate;

%%

int main ()
{
    if (yyparse() == 0){
        // successful parsing
        printf("OK\n");
        return 0;
    }
    else{
        // parse error
        printf("ERROR\n");
        return 1;
    }
}