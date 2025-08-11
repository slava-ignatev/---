--Первый CTE. Считаем агрегирующую оконную функцию в рамках клиента и месяца платежа, сортируем по дате платежа, чтобы посчитать накопительный итог по платежам
WITH 
MonthlyAgg AS (
    SELECT 
        CLIENT_ID,
        PAY_DATE,
        PAY_SUM,
        SUM(PAY_SUM) OVER (PARTITION BY CLIENT_ID, DATE_TRUNC('month', PAY_DATE) ORDER BY PAY_DATE) AS running_total
    FROM PAYMENTS
),
--Второй CTE. Считаем оконную функцию смещения, выводим предыдущий накопленный платеж в рамках клиента и месяца платежа, сортируем по дате платежа
WithPrevTotal AS (
    SELECT 
        CLIENT_ID,
        PAY_DATE,
        PAY_SUM,
        running_total,
        LAG(running_total) OVER (PARTITION BY CLIENT_ID, DATE_TRUNC('month', PAY_DATE) ORDER BY PAY_DATE) AS prev_running_total
    FROM MonthlyAgg
)
--Основной запрос
SELECT 
    CLIENT_ID AS "Идентификатор клиента",
    PAY_DATE AS "Дата платежа",
    PAY_SUM AS "Сумма платежа",
    --Создаем условие
    CASE
	      --Если накопленная сумма меньше 400 000, выводим в коммиссию 0 
        WHEN running_total <= 400000 THEN 0
        ELSE (
            -- Иначе считаем комиссию за новые целые пакеты 100k, которые появились с последнего платежа. Округляем вверх
            (CEILING((running_total - 400000) / 100000) - 
             CEILING(COALESCE(GREATEST(prev_running_total - 400000, 0), 0) / 100000)) * 2000
             )
    END AS "COMISS"
FROM WithPrevTotal
ORDER BY CLIENT_ID, PAY_DATE;