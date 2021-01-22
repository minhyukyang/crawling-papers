## RSelenium 사전 설치
# 1. 사전 환경 세팅 -------------------------------------------------------------
#
# 1) chromedriver 설치
# - 링크 : https://sites.google.com/a/chromium.org/chromedriver/
# * 현재 설치된 chrome 버전에 맞는 드라이버 다운로드
#
# 2) selenium 설치
# - 프로그램을 이용해 자동화된 웹 테스트를 수행할 수 있도록 해주는 프레임 워크 (https://namu.wiki/w/Selenium)
# - 다운로드 링크 : https://www.seleniumhq.org/download/
# * Selenium Server (Grid) > stable version 받기
#
# 3) 설치
# 1), 2)를 c:\rselenium 폴더에 넣기
# chrome drive는 동일 폴더에 압출 해제 하기
#
# 4) Selenium 서버 띄우기 
# 명령 프롬프트 실행 (단축키 : Ctrl + R > "cmd")
# 설치 폴더로 이동 : "cd c:\rselenium"
# 명령어 입력 : "java -jar selenium-server-standalone-3.141.59.jar -port 4445"
# -> "Selenium Server is up and running on port 4445" 이란 로그가 나타나면 성공

# DBPia Cralwer 참고
# - ref1 : https://github.com/chanhee-kang/DBpia_crawler/blob/master/dbpp.py
# - ref2 : https://wikidocs.net/67127
# # java -jar selenium-server-standalone-3.141.59.jar -port 4445


# 0. 환경세팅 -----------------------------------------------------------------

library(RSelenium)
library(rvest)
library(dplyr)
library(stringr)
library(tidyverse)
library(tictoc)

print("start crawling..")

### chrome driver 실행

remDr <- remoteDriver(
  remoteServerAddr="localhost",
  port=4445L,
  browserName="chrome")

remDr$open() # chrome 창 생성

# 기본 설정값
dbpia_url <- "https://www.dbpia.co.kr/"
keyword <- "스마트팩토리"
start_year <- "2010"
end_year <- "2021"

# 1. 스마트팩토리 검색 ------------------------------------------------------------

# DBpia 접속
remDr$navigate(dbpia_url) # driver.get(url) 

# 키워드 입력
elem_keyword_id <- remDr$findElement(using='xpath', value='//*[@id="keyword"]')
elem_keyword_id$clickElement()
elem_keyword_id$clearElement() # elem_login.clear()
elem_keyword_id$sendKeysToElement(list(keyword)) # elem_login.send_keys('ID') 

# elem_search_button <- remDr$findElement(using='xpath', value='//*[@id="header"]/div[5]/div[6]/div[1]/div[1]/a')
elem_search_button <- remDr$findElement(using='xpath', value='//*[@id="header"]/div[5]/div[6]/div[2]/div[1]/a')
elem_search_button$clickElement() # driver.find_element_by_xpath(xpath).click() 

# 기간 지정 
elem_start_year <- remDr$findElement(using='xpath', value='//*[@id="dev_sartYY"]')
elem_start_year$clickElement()
elem_start_year$clearElement()
elem_start_year$sendKeysToElement(list(start_year))

elem_end_year <- remDr$findElement(using='xpath', value='//*[@id="dev_endYY"]')
elem_end_year$clickElement()
elem_end_year$clearElement()
elem_end_year$sendKeysToElement(list(end_year))

elem_period_click_button <- remDr$findElement(using='xpath', value='//*[@id="sidebar"]/form/div[3]/div/div[1]/ul/li[4]/p/button')
elem_period_click_button$clickElement()

# '자료유형' 체크박스 선택 // 미구현
# - 학술대회자료, 학술저널 등
# elem_pub_check_1 <- remDr$findElement(using='xpath', value='//*[@id="pub_check_sort3_0"]')
# elem_pub_check_1$clickElement() # driver.find_element_by_xpath(xpath).click()
# elem_pub_check_2 <- remDr$findElement(using='xpath', value='//*[@id="dev_plctType"]/li[1]/span/label')
# elem_pub_check_2$clickElement() # driver.find_element_by_xpath(xpath).click()
 
# '더보기' 확장 -> 마지막 페이지 까지
more_count <- 0

# error 처리
# - https://stackoverflow.com/questions/53497343/r-cannot-break-the-while-loop-with-use-of-trycatch

while (TRUE) {
  Sys.sleep(1) # time.sleep(4)
  
  res <- try({
    click_more <- remDr$findElement(using = 'xpath', value = '//*[@id="contents"]/div[2]/div[3]/div[3]/div[3]/div/a')
    remDr$mouseMoveToLocation(webElement = click_more)
    remDr$click(buttonId = 'LEFT')
    # click_more$clickElement() # driver.find_element_by_xpath(xpath).click()
    
    more_count <- more_count + 1
    # sprintf(" + page [%d] ", more_count)
  }, silent = TRUE)
  if (inherits(res, "try-error")){
    message("done")
    break
  } else {
    message(more_count)
  }
}

# `$clickElement()`로 동작하지 않을 때
# remDr$mouseMoveToLocation(webElement = elem_period_click_button)
# remDr$click(buttonId = 'LEFT')


# 2. 페이지 가져오기 -------------------------------------------------------------

items_source <- remDr$getPageSource()[[1]]
items_source_html <- read_html(items_source)
#dev_search_list > li:nth-child(487)
#dev_search_list > li:nth-child(481)

items <- items_source_html %>% html_nodes("#dev_search_list > li")

# 논문제목, 저자, 퍼블리셔, 저널명, 볼륨, 날짜, 초록, 다운로드ID(논문)
items_cnt <-  length(items)
results <- tibble()

print("start parsing")

for (i in 1:items_cnt){
# for (i in 1:5){
  
  if (i %% 10 == 0){
    sprintf(" parsing.. [%d/%d]", i, items_cnt)
  }
  
  tryCatch({
    title <- items_source_html %>% html_nodes("#dev_search_list > li") %>% .[i] %>% html_nodes(".titWrap") %>% html_nodes("h5 > a") %>% html_text()
    title <- ifelse(length(title) == 0, '', title)
  }, error = function(e){
    title <- ''
  })
  
  tryCatch({
    author <- items_source_html %>% html_nodes("#dev_search_list > li") %>% .[i] %>% html_nodes(".author") %>% html_text()
    author <- ifelse(length(author) == 0, '', author)
  }, error = function(e){
    author <- ''
  })
  
  tryCatch({
    publisher <- items_source_html %>% html_nodes("#dev_search_list > li") %>% .[i] %>% html_nodes(".publisher") %>% html_text() 
    publisher <- ifelse(length(publisher) == 0, '', publisher)
  }, error = function(e){
    publisher <- ''
  })
  
  tryCatch({
    journal <- items_source_html %>% html_nodes("#dev_search_list > li") %>% .[i] %>% html_nodes(".journal") %>% html_text() 
    journal <- ifelse(length(journal) == 0, '', journal)
  }, error = function(e){
    journal <- ''
  })
  
  tryCatch({
    volume <- items_source_html %>% html_nodes("#dev_search_list > li") %>% .[i] %>% html_nodes(".volume") %>% html_text() 
    volume <- ifelse(length(volume) == 0, '', volume)
  }, error = function(e){
    volume <- ''
  })
  
  tryCatch({
    date <- items_source_html %>% html_nodes("#dev_search_list > li") %>% .[i] %>% html_nodes(".date") %>% html_text()
    date <- ifelse(length(date) == 0, '', date)
  }, error = function(e){
    date <- ''
  })
  
  tryCatch({
    download_id <- items_source_html %>% html_nodes("#dev_search_list > li") %>% .[i] %>% html_nodes("div > div > p > button") %>% html_attr("id") %>% tibble() %>% drop_na() %>% pull()
    download_id <- ifelse(length(download_id) == 0, '', download_id)
  }, error = function(e){
    download_id <- ''
  })
  
  tmp <- tibble(
    id = as.character(i),
    title = as.character(title),
    author = as.character(author),
    publisher = as.character(publisher),
    journal = as.character(journal),
    volume = as.character(volume),
    date = as.character(date),
    download_id = as.character(download_id)
  )
  print(tmp)
  
  # results <- rbind(results, tmp)
  results <- bind_rows(results, tmp)
  # print(results[i,])
}

print(results)

#download_NODE10507560
#download_NODE10496242

# 3. 논문 다운로드 --------------------------------------------------------------

# extract download list
# items_source_html %>% html_nodes("#dev_search_list > li") %>% .[i] %>% html_nodes("div > div > p > button") %>% html_attr("id") %>% tibble() %>% drop_na() %>% pull()

# download_list <- items_source_html %>% html_nodes("#dev_search_list > li > div > div > p > button") %>% html_attr("id") %>% tibble() %>% drop_na() %>% pull()
# length(download_list)

# 다운로드 버튼이 없는 자료 제외
download_list <- results %>% filter(download_id != '')
nrow(download_list)

print("Download papers...")

tic()
for(i in 1:nrow(download_list)){
  
  download_id <- capture.output(cat(paste0("//*[@id='",download_list$download_id[i],"']")))
  download_btn <- remDr$findElement(using="xpath", value=download_id)
  # download_btn <- remDr$findElement(using='xpath', value='//*[@id="download_NODE10507560"]')
  download_btn$clickElement()

  cat("\n[",i,"/",nrow(download_list),"] ", download_list$title[i], sep="")
  Sys.sleep(3) # time.sleep(4)
  
  tryCatch({
    recommend_btn <-  remDr$findElement(using="xpath", value="//*[@id='pub_modalRecommendThesis']/div/div[1]/button")
    recommend_btn$clickElement()  
  }, error = function(e){
    next
  })
  Sys.sleep(2) # time.sleep(4)  
}
toc()

print("Complete...")