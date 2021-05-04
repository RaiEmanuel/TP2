%{
#include <iostream>
#include <stack>
#include <string>
#include <fstream>
#include <algorithm>
using namespace std;

ifstream fin;
stack<string> stackTags;
stack<string> stackTexts;
unsigned short int level = 0;
void repeat (unsigned short int n, string pattern);

/*
<p> <h1> <b> c++ </b> is </h1> awesome! </p>

stackTags - Pilha que representa os níveis e ordem de tags para fechar
        +-------+
lvl 2   |   b   |
lvl 1   |   h1  |
lvl 0   |   p   |
        +-------+
stackTexts - Pilha que representa os textos de cada nível
        +---------------+   
lvl 2   |   c++         |
lvl 1   |   is          |
lvl 0   |   awesome!    |
        +---------------+       
*/
unsigned short int tags = 0, lines = 0, caracs = 0;

%}

%option noyywrap

%x TAG
%x CLOSETAG
%x TEXT
%x CLOSETEXT
%x ATTRIBUTE
whites [ \n\t]*
singleTag (br|img)
pairTag (html|head|style|title|body|h1|h2|h3|h4|h5|h6|p|b|i|table|tr|th|td|ul|li|a)
attributes ([ \t]+[a-zA-Z]+{whites}={whites}\"[^\n({whites}">")]*+\")*

%%  
"<""!DOCTYPE html"">"                           {++tags;++lines;}
{whites}"<"                                     {BEGIN TAG;}
[ \t]*                                          ;                                                
<TAG>!--[^(-)(-)">"]*--">"                      {
                                                    //cout <<"***comment"<<YYText()<<"***"<<endl;
                                                    //Não quebra linha
                                                    BEGIN TEXT;
                                                }
<TAG>"/"                                        {BEGIN CLOSETAG;}
<TAG>{singleTag}                            {   
                                                ++tags;
                                                repeat(level, "|\t");
                                                cout << "+--<" << YYText();
                                                //Não coloca na pilha porque não precisa fechar
                                                //Nem precisa colocar texto na pilha
                                                BEGIN ATTRIBUTE;
                                            }
<TAG>{pairTag}                              {
                                                ++tags;
                                                repeat(level, "|\t");
                                                cout << "+--<" << YYText();
                                                stackTags.push(YYText());
                                                stackTexts.push("");//cria texto inicial para aquele nível
                                                ++level;
                                                BEGIN ATTRIBUTE;
                                            }              
 <TAG>(.|\n)                                {cout << "erro tag ["<<YYText()<<"]"<<endl;}
<CLOSETAG>{pairTag}                         {
                                                string readedTag = YYText();
                                                if(!readedTag.compare(stackTags.top())){
                                                    if(stackTexts.top().size() > 0){
                                                        repeat(level, "|\t");
                                                        caracs += stackTexts.top().size();
                                                        cout << "+--Texto["<<stackTexts.top().size() <<"]"<<endl;
                                                    }
                                                    stackTexts.pop();
                                                    stackTags.pop();
                                                    --level;
                                                    repeat(level, "|\t");
                                                    cout << "+--</" << YYText()<<">" <<endl;
                                                }
                                            }
<CLOSETAG>">"                               {BEGIN TEXT;}
<ATTRIBUTE>{attributes}                     {
                                              cout <<YYText();
                                            }
<ATTRIBUTE>{whites}">"                      {
                                               cout << ">" << endl;
                                               BEGIN TEXT;
                                            }
<TEXT>{whites}"<""style"">"(.|\n)*"<""/""style"">"  {   
                                                        //conta \n do style
                                                        string styleText = YYText();
                                                        int occcurrences = count(styleText.begin(), styleText.end(), '\n');
                                                        lines += occcurrences;
                                                        repeat(level, "|\t");
                                                        cout << "+--<style>"<<endl;
                                                        repeat(level, "|\t");
                                                        cout << "+--</style>"<<endl;
                                                    } 
<TEXT>{whites}"<"                           {
                                                string ignoredText = YYText();
                                                int occcurrences = count(ignoredText.begin(), ignoredText.end(), '\n');
                                                lines += occcurrences;
                                                //cout << "comecou tag pelo text "<<YYText()<<endl;
                                                BEGIN TAG;
                                            }
                                           
<TEXT>{whites}[^"<"\n]+{whites}("<")        {
                                                //cout <<"leu  comecando o prox["<<YYText()<<"]"<<endl;
                                                string readedText = YYText();
                                                readedText.erase(readedText.end() - 1);
                                                if(stackTexts.size() > 0)
                                                    stackTexts.top().append(readedText);
                                                repeat(level, "|\t");
                                                caracs += stackTexts.top().size();
                                                cout << "+--Texto["<<stackTexts.top().size() <<"]"<<endl;
                                                stackTexts.top() = "";
                                                
                                                BEGIN TAG;   
                                            }                                            
<TEXT>{whites}[^\n"<"]+{whites}(\n)      {
                                                //cout <<"leu com /n["<<YYText()<<"]"<<endl;
                                                ++lines;
                                                string readedText = YYText();
                                                readedText.erase(readedText.end() - 1);
                                                if(stackTexts.size() > 0)
                                                    stackTexts.top().append(readedText);
                                                repeat(level, "|\t");
                                                caracs += stackTexts.top().size();
                                                cout << "+--Texto["<<stackTexts.top().size() <<"]"<<endl;
                                                stackTexts.top() = "";   
                                            }
<TEXT>(.|\n)                                {
                                                if(stackTexts.size() > 0)
                                                    stackTexts.top().append(YYText());
                                            }
(.|\n)                                      {cout << "erro initial = ["<<YYText()<<"]"<<endl;}
%%

void repeat (unsigned short int n, string pattern){
    for(unsigned short int i = 0; i < n; ++i){
        cout << pattern;
    }
}

int main(int argc, char ** argv){
    yyFlexLexer lexer;
    if(argc > 1){
        lexer.switch_streams(&fin);
        fin.open(argv[1]);
    }
    
	lexer.yylex();
    cout << endl << "Tags HTML: " << tags<<endl;
    cout << "Linhas: "<<lines<<endl;
    cout << "Caracteres: " <<caracs<<endl;

    return EXIT_SUCCESS;
}