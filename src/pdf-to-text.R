<<<<<<< HEAD
# library(pdftools)
# 
# pdf_2 <- pdftools::pdf_text("crawling-papers-using-r/data/raw/주요국 스마트팩토리 해외 동향.pdf")
# pdf_2

# install.packages("textreadr")
library(textreadr)
library(tidyverse)

pdf_1 <- textreadr::read_pdf("crawling-papers-using-r/data/raw/주요국 스마트팩토리 해외 동향.pdf")

# DBPia 정보(1페이지) 제외
pdf_1 %>% 
  filter(page_id != 1)

# 전처리 : 2칸 이상 빈칸 -> 1칸 빈칸
pdf_1 %>% 
  filter(page_id != 1) %>% 
  mutate(text = gsub("\\s+", " ", text)) %>% 
  select(text) %>% 
  as.data.frame()

## 전처리 
# - Email 제거
# - tap 제거
# - 다단 구분
# - section 구분

# # 요약 부분 추출
# pdf_1 %>% 
#   filter(page_id != 1) %>% 
#   mutate(text = gsub("\\s+", " ", text)) %>% 
#   filter(str_detect(text, "요약|요 약")) %>% 
#   select(element_id) %>% 
#   pull()
#   
#   
=======
# library(pdftools)
# 
# pdf_2 <- pdftools::pdf_text("crawling-papers-using-r/data/raw/주요국 스마트팩토리 해외 동향.pdf")
# pdf_2

# install.packages("textreadr")
library(textreadr)
library(tidyverse)

pdf_1 <- textreadr::read_pdf("crawling-papers-using-r/data/raw/주요국 스마트팩토리 해외 동향.pdf")

# DBPia 정보(1페이지) 제외
pdf_1 %>% 
  filter(page_id != 1)

# 전처리 : 2칸 이상 빈칸 -> 1칸 빈칸
pdf_1 %>% 
  filter(page_id != 1) %>% 
  mutate(text = gsub("\\s+", " ", text)) %>% 
  select(text) %>% 
  as.data.frame()

## 전처리 
# - Email 제거
# - tap 제거
# - 다단 구분
# - section 구분

# # 요약 부분 추출
# pdf_1 %>% 
#   filter(page_id != 1) %>% 
#   mutate(text = gsub("\\s+", " ", text)) %>% 
#   filter(str_detect(text, "요약|요 약")) %>% 
#   select(element_id) %>% 
#   pull()
#   
#   
  
>>>>>>> 20cec577d5515357a8b03b26a77a1ee171cba753
