# - ref1 : https://github.com/chanhee-kang/DBpia_crawler/blob/master/dbpp.py
# - ref2 : https://wikidocs.net/67127
# # java -jar selenium-server-standalone-3.141.59.jar -port 4445

library(RSelenium)
library(rvest)
library(dplyr)

searchQ <- ""
startYear <- 2010
endYear <- 2021
  
print("start crawling..")

remDr <- remoteDriver(
  remoteServerAddr="localhost",
  port=4445L,
  browserName="chrome")

remDr$open()

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

# 기간 지정 및 체크박스 설정
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

# '자료유형' 체크박스 선택
# - 학술대회자료, 학술저널 등
# elem_pub_check_1 <- remDr$findElement(using='xpath', value='//*[@id="pub_check_sort3_0"]')
# elem_pub_check_1$clickElement() # driver.find_element_by_xpath(xpath).click()
# elem_pub_check_2 <- remDr$findElement(using='xpath', value='//*[@id="dev_plctType"]/li[1]/span/label')
# elem_pub_check_2$clickElement() # driver.find_element_by_xpath(xpath).click()
 
# '더보기' 확장 -> 마지막 페이지 까지
more_count <- 0

tryCatch({
  while (TRUE) {
    Sys.sleep(1) # time.sleep(4)
    
    click_more <- remDr$findElement(using = 'xpath', value = '//*[@id="contents"]/div[2]/div[3]/div[3]/div[3]/div/a')
    remDr$mouseMoveToLocation(webElement = click_more)
    remDr$click(buttonId = 'LEFT')
    # click_more$clickElement() # driver.find_element_by_xpath(xpath).click()
    
    more_count <- more_count + 1
    # sprintf(" + page [%d] ", more_count)
    print(more_count)
  }
}, error = function(e) {
  # print(e)
  print("done.")
  break
})

# `$clickElement()`로 동작하지 않을 때
# remDr$mouseMoveToLocation(webElement = elem_period_click_button)
# remDr$click(buttonId = 'LEFT')


# 2. 페이지 가져오기 -------------------------------------------------------------

items_source <- remDr$getPageSource()[[1]]
items_source_html <- read_html(items_source)
#dev_search_list > li:nth-child(487)
#dev_search_list > li:nth-child(481)

items <- items_source_html %>% html_nodes("#dev_search_list > li")

# 논문제목, 저자, 퍼블리셔, 저널명,볼륨,날짜,초록
items_cnt <-  length(items)
results <- tibble()

print("start parsing")

for (i in 1:items_cnt){
  
  
  if (i %% 10 == 0){
    sprintf(" parsing.. [%d/%d]", i, items_cnt)
  }
  
  tryCatch({
    title <- items_source_html %>% html_nodes("#dev_search_list > li") %>% html_nodes(".titWrap") %>% html_nodes("h5 > a") %>% html_text() %>% .[i]
  }, error = function(e){
    title <- ''
  })
  
  tryCatch({
    author <- items_source_html %>% html_nodes("#dev_search_list > li") %>% html_nodes(".author") %>% html_text() %>% .[i]
  }, error = function(e){
    author <- ''
  })
  
  tryCatch({
    publisher <- items_source_html %>% html_nodes("#dev_search_list > li") %>% html_nodes(".publisher") %>% html_text() %>% .[i]
  }, error = function(e){
    publisher <- ''
  })
  
  tryCatch({
    journal <- items_source_html %>% html_nodes("#dev_search_list > li") %>% html_nodes(".journal") %>% html_text() %>% .[i]
  }, error = function(e){
    journal <- ''
  })
  
  tryCatch({
    volume <- items_source_html %>% html_nodes("#dev_search_list > li") %>% html_nodes(".volume") %>% html_text() %>% .[i]
  }, error = function(e){
    volume <- ''
  })
  
  tryCatch({
    date <- items_source_html %>% html_nodes("#dev_search_list > li") %>% html_nodes(".date") %>% html_text() %>% .[i]
  }, error = function(e){
    date <- ''
  })
  
  # 논문 다운로드 구현
  # item 별로 url를 추출하여 '다운로드' 버튼 클릭

  tmp <- tibble(
    "title" = as.character(title),
    "author" = as.character(author),
    "publisher" = as.character(publisher),
    "journal" = as.character(journal),
    "volume" = as.character(volume),
    "date" = as.character(date)
  )
  
  results <- bind_rows(results, tmp)
  
  print(results[i,])
}

print(results)

# 잔여 작업 -------------------------------------------------------------------

# 초록 추출
# 논문 다운로드 구현
# 논문 다운로드 후 PDF 추출출

