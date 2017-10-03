library(tm)
library(SnowballC)
library(wordcloud)
library(XML)
library(RODBC)

Sys.setenv(JAVA_HOME="C:\\Program Files\\Java\\jre1.8.0_91")
library(rJava)
library(RWeka)

#path <- "C:\\Temp\\Anuncios_Ruby.csv"
path <- "M:\\TMP\\Anuncios_Vendedor.csv"
#path <- "M:\\TMP\\Anuncios_RH.csv"

#path <- "C:\\Temp\\CVs_Ruby.csv"
#path <- "M:\\TMP\\CVs_Engenheiro.csv"

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
#docs <- tm_map(docs, removeWords, stopwords("portuguese"))   
#docs <- tm_map(docs, stemDocument,language="portuguese")   
docs <- tm_map(docs, PlainTextDocument) 

# Remove some words we'd like to ignore
docs <- tm_map(docs, removeWords, c("nomecolun"))   

# Create function from RWeka
#Bigrama
BigramTokenizer <- function(x) NGramTokenizer(x, Weka_control(min = 2, max = 2))
dtm.ng <- DocumentTermMatrix(docs, control = list(tokenize = BigramTokenizer))
#Trigrama
TrigramTokenizer <- function(x) NGramTokenizer(x, Weka_control(min = 3, max = 3))
dtm.ng <- DocumentTermMatrix(docs, control = list(tokenize = TrigramTokenizer))

freq <- sort(colSums(as.matrix(dtm.ng)), decreasing=TRUE)  # Check the frequency

#rownames(m) <- paste(substring(rownames(m),1,3),rep("..",nrow(m)),substring(rownames(m), nchar(rownames(m))-12,nchar(rownames(m))-4))
rownames(m1) <- paste(substring(rownames(m1),1,3),rep("..",nrow(m1)),substring(rownames(m1), nchar(rownames(m1))-12,nchar(rownames(m1))-4))


# Save frequency table to file
#write.table(freq,file = "C:\\Temp\\Freq_CVs_Ruby.csv",sep = ";")
unlink("M:\\TMP\\TMP_Freq.csv", recursive = FALSE, force = FALSE)
write.table(freq,file = "M:\\TMP\\TMP_Freq.csv",sep = ";")

table <- data.frame(word = names(freq),freq = freq)

# wordcloud(words = table$word,freq = table$freq,max.words = 100,random.order = FALSE,rot.per=0.35, 
#           colors=brewer.pal(8, "Dark2"))

unlink("M:\\TMP\\wordcloud_vendedor.png", recursive = FALSE, force = FALSE)
pal2 <- brewer.pal(8,"Dark2")
png("M:\\TMP\\wordcloud_vendedor.png", width=1500,height=1200)
wordcloud(table$word,table$freq, scale=c(8,.2),min.freq=10,
          max.words=100, random.order=FALSE, rot.per=.15, colors=pal2)
dev.off()