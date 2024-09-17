if (!requireNamespace("httr", quietly = TRUE)) {
  install.packages("httr")
}
if (!requireNamespace("jsonlite", quietly = TRUE)) {
  install.packages("jsonlite")
}
if (!requireNamespace("ggplot2", quietly = TRUE)) {
  install.packages("ggplot2")
}
library(httr)
library(jsonlite)
library(ggplot2)

CITY <- "Dourados"
API_KEY <- "c60a4792ccbe5983e113c048825b78fb"

output_message <- ""

link_temp <- paste0('https://api.openweathermap.org/data/2.5/weather?q=', URLencode(CITY), '&appid=', API_KEY, '&lang=pt_br')

response <- GET(link_temp)

if (status_code(response) == 200) {
  dictionary_res <- content(response, as = "parsed")
  
  climate <- dictionary_res$weather[[1]]$description
  temperature <- dictionary_res$main$temp - 273.15
  
  formatted_string <- sprintf("Em %s, o clima está de %s, com temperatura de %.2f°C.\n", CITY, climate, round(temperature, 2))
  output_message <- paste(output_message, formatted_string, sep = "")
  
} else {
  output_message <- paste(output_message, "Erro na requisição do clima. Status code:", status_code(response), "\n", sep = "")
}

link_rain <- paste0("https://api.openweathermap.org/data/2.5/forecast?q=", URLencode(CITY), "&appid=", API_KEY, "&units=metric")

response <- GET(link_rain)

if (response$status_code == 200) {
  data <- fromJSON(content(response, "text", encoding = "UTF-8"))
  previsao <- data$list
  
  dados_chuva <- data.frame(
    data = as.POSIXct(previsao$dt, origin = "1970-01-01", tz = "UTC"),
    prob_chuva = sapply(previsao$pop, function(x) paste0(round(x * 100), "%"))  # Convertendo para porcentagem e adicionando o símbolo %
  )
  
  output_message <- paste(output_message, sprintf("\nA probabilidade de chuva em %s de 3 em 3h nos próximos 5 dias é:\n", CITY), sep = "")
  output_message <- paste(output_message, paste(capture.output(print(dados_chuva)), collapse = "\n"), "\n\n", sep = "")
  
} else {
  output_message <- paste(output_message, "Erro na requisição de previsão de chuva. Status code:", response$status_code, "\n", sep = "")
}

ggplot(data = dados_chuva, aes(x = data, y = prob_chuva)) +
  geom_line(color = "blue", size = 1) +
  geom_point(color = "red", size = 2) +
  labs(title = paste("Probabilidade de Chuva em", CITY),
       x = "Data e Hora",
       y = "Probabilidade de Chuva (%)") +
  theme_minimal() +
  scale_x_datetime(date_labels = "%d-%b %H:%M", date_breaks = "12 hours") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

cat(output_message)
