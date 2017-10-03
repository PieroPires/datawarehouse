library(tm)
library(SnowballC)
library(wordcloud)
library(XML)
library(RODBC)

#path <- "C:\\Temp\\Anuncios_Ruby.csv"
#path <- "M:\\TMP\\Anuncios_Vendedor.csv"
#path <- "M:\\TMP\\Anuncios_RH.csv"

#path <- "C:\\Temp\\CVs_Ruby.csv"
path <- "M:\\TMP\\CVs_Engenheiro.csv"

texto_completo <- read.csv(path,encoding = "UTF-8",sep = ";",header = TRUE)

qtd_texto <- length(texto_completo$Texto)
plain.text <- ""

# Delete TMP file
unlink("M:\\TMP\\TMP_Texto.csv", recursive = FALSE, force = FALSE)

for(i in 1:qtd_texto) 
{
  print(i)
  #doc <- htmlParse(texto_completo$Texto[i],asText=TRUE,encoding="UTF-8")
  doc <-  tryCatch(htmlParse(texto_completo$Texto[i],asText=TRUE,encoding="UTF-8"),
                   error = function(e) { 
                     return(NULL)
                   } )
  
  # We concat all text together because we'll need all stuff when we build the "wordcloud"
  if (!is.null(doc)) {
    
    plain.text <- paste(xpathSApply(doc, "//text()[not(ancestor::script)][not(ancestor::style)][not(ancestor::noscript)][not(ancestor::form)]", xmlValue))
    plain.text <- gsub("\t","",gsub("\u0095","",gsub("\n","",gsub("\r","",plain.text))))
    write.table(plain.text,file = "M:\\TMP\\TMP_Texto.csv",append = TRUE,col.names=c("Nome_Coluna"))
  }
  
  plain.text <- ""
  
}

plain.text <- read.csv("M:\\TMP\\TMP_Texto.csv",sep = ";",header = TRUE)
plain.text <- iconv(plain.text$Nome_Coluna, to='ASCII//TRANSLIT')

# Start to clean all text
docs <- Corpus(VectorSource(plain.text)) # Format to "Corpus" (it's necessary for tm package)
docs <- tm_map(docs, removePunctuation)   
docs <- tm_map(docs, stripWhitespace) 
docs <- tm_map(docs, removeNumbers)   
docs <- tm_map(docs, tolower)   
docs <- tm_map(docs, removeWords, stopwords("portuguese"))   
docs <- tm_map(docs, stemDocument,language="portuguese")   
docs <- tm_map(docs, PlainTextDocument) 

# Remove some words we'd like to ignore
docs <- tm_map(docs, removeWords, c("nomecolun"))   
docs <- tm_map(docs, removeWords, c("acima","analise",
                                    "anos",
                                    "areas",
                                    "atuar",
                                    "auxilio",
                                    "bons",
                                    "buscamos",
                                    "cargo",
                                    "conhecimento",
                                    "conhecimentos",
                                    "contratacao",
                                    "desejavel",
                                    "devera",
                                    "diferenciais",
                                    "diferencial",
                                    "disponibilidade",
                                    "empresa",
                                    "equipe",
                                    "experiencia",
                                    "ferramentas",
                                    "grande",
                                    "grau",
                                    "horario",
                                    "Janeiro",
                                    "medio",
                                    "minima",
                                    "minimo",
                                    "missao",
                                    "novo",
                                    "novos",
                                    "oferecemos",
                                    "outros",
                                    "pequeno",
                                    "perfil",
                                    "qualidade",
                                    "regiao",
                                    "requisitos",
                                    "Rio",
                                    "Sao Paulo",
                                    "sempre",
                                    "ser",
                                    "ter",
                                    "texto",
                                    "trabalhar",
                                    "trabalho",
                                    "utilizando",
                                    "utilizar",
                                    "vivencia",
                                    "sao",
                                    "nao",
                                    "ate",
                                    "todos",
                                    "equipes",
                                    "creche"
)

)

dtm <- DocumentTermMatrix(docs, control = list(bounds=list(global = c(4, Inf))))  # transform to Term Matrix

freq <- sort(colSums(as.matrix(dtm)), decreasing=TRUE)  # Check the frequency

# Save frequency table to file
#write.table(freq,file = "C:\\Temp\\Freq_CVs_Ruby.csv",sep = ";")
unlink("M:\\TMP\\TMP_Freq.csv", recursive = FALSE, force = FALSE)
write.table(freq,file = "M:\\TMP\\TMP_Freq.csv",sep = ";")

wordcloud(docs,max.words = 100,random.order = FALSE,rot.per=0.35, 
          colors=brewer.pal(8, "Dark2"))

