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
"<""!DOCTYPE html"">"                           {
                                                    ++tags;
                                                    ++lines;
                                                }
{whites}"<"                                     {
                                                    //detecta inicio de uma tag
                                                    BEGIN TAG;
                                                }
[ \t]*                                          ;//ignora espaços antes de achar uma tag útil                                                
<TAG>!--[^(-)(-)">"]*--">"                      {
                                                    //cout <<"***comment"<<YYText()<<"***"<<endl;
                                                    //Não quebra linha
                                                    BEGIN TEXT;
                                                }
<TAG>"/"                                        {   
                                                    //detecta que é uma tag de fechamento
                                                    BEGIN CLOSETAG;
                                                }
<TAG>{singleTag}                                {   
                                                    //detecta tag única
                                                    ++tags;
                                                    repeat(level, "|\t");
                                                    cout << "+--<" << YYText();
                                                    //Não coloca na pilha porque não precisa fechar
                                                    //Nem precisa colocar texto na pilha
                                                    BEGIN ATTRIBUTE;
                                                }
<TAG>{pairTag}                                  {
                                                    ++tags;
                                                    repeat(level, "|\t");
                                                    cout << "+--<" << YYText();
                                                    stackTags.push(YYText());
                                                    stackTexts.push("");//cria texto inicial para aquele nível
                                                    ++level;
                                                    BEGIN ATTRIBUTE;
                                                }                                                    
<CLOSETAG>{pairTag}                             {
                                                    //fechamento de uma tag e exibição de suas variáveis
                                                    string readedTag = YYText();
                                                    //tag lida e a do topo da pilha devem ser iguais para que a ordem de fechamento esteja correta
                                                    if(!readedTag.compare(stackTags.top())){
                                                        if(stackTexts.top().size() > 0){
                                                            repeat(level, "|\t");
                                                            caracs += stackTexts.top().size();
                                                            cout << "+--Texto["<<stackTexts.top().size() <<"]"<<endl;
                                                        }
                                                        stackTexts.pop();//apaga tag da pilha de tags
                                                        stackTags.pop();//apaga nivel de texto pois a tag foi apagada.
                                                        //o nivel atual agora está disponvel para a próxima tag que chegar
                                                        --level;//diminui para deixar o nível atual disponível para a próxima tag que chegar
                                                        repeat(level, "|\t");
                                                        cout << "+--</" << YYText()<<">" <<endl;
                                                    }
                                                }
<CLOSETAG>">"                               {
                                                //fechou tag pareada, parte para detectar seu texto útil associado
                                                BEGIN TEXT;
                                            }
<ATTRIBUTE>{attributes}                     {
                                              //exibe atributo encontrado
                                              cout <<YYText();
                                            }
<ATTRIBUTE>{whites}">"                      {
                                                //apenas procura > final da abertura da tag
                                               cout << ">" << endl;
                                               BEGIN TEXT;
                                            }
<TEXT>{whites}"<""style"">"(.|\n)*"<""/""style"">"  {   
                                                        //conta \n do style e ignora resto do texto
                                                        string styleText = YYText();
                                                        int occcurrences = count(styleText.begin(), styleText.end(), '\n');
                                                        lines += occcurrences;
                                                        repeat(level, "|\t");
                                                        cout << "+--<style>"<<endl;
                                                        repeat(level, "|\t");
                                                        cout << "+--</style>"<<endl;
                                                    } 
<TEXT>{whites}"<"                           {
                                                //texto ignorado entre abertura de tags diferentes
                                                string ignoredText = YYText();
                                                int occcurrences = count(ignoredText.begin(), ignoredText.end(), '\n');
                                                lines += occcurrences;
                                                BEGIN TAG;
                                            }
<TEXT>{whites}[^"<"\n]+{whites}("<")        {
                                                //linha de texto util antes de comecar o nivel de outra tag
                                                string readedText = YYText();
                                                readedText.erase(readedText.end() - 1);//deleta <
                                                if(stackTexts.size() > 0)
                                                    stackTexts.top().append(readedText);
                                                repeat(level, "|\t");
                                                caracs += stackTexts.top().size();
                                                cout << "+--Texto["<<stackTexts.top().size() <<"]"<<endl;
                                                stackTexts.top() = "";//limpa nivel da pilha para pegar textos quando a pilha voltar novamente par ao nivel atual
                                                //agora o nivel sera nivel + 1 pois abrir-se-á uma nova tag
                                                BEGIN TAG;   
                                            }                                            
<TEXT>{whites}[^\n"<"]+{whites}(\n)         {
                                                //linha de texto util com \n
                                                ++lines;
                                                string readedText = YYText();
                                                readedText.erase(readedText.end() - 1);//apaga o \n ou <, pois não são texto útil.
                                                if(stackTexts.size() > 0)
                                                    stackTexts.top().append(readedText);//adiciona texto detectado na pilha
                                                repeat(level, "|\t");
                                                caracs += stackTexts.top().size();
                                                cout << "+--Texto["<<stackTexts.top().size() <<"]"<<endl;
                                                stackTexts.top() = "";//zera texto da tag do nivel atual para poder contar caracteres da próxima linha
                                            }
<TEXT>(.|\n)                                {
                                                //caracteres que sobraram
                                                if(stackTexts.size() > 0)
                                                    stackTexts.top().append(YYText());
                                            }
(.|\n)                                      cout << "erro initial = ["<<YYText()<<"]"<<endl;
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