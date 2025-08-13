--Первый CTE. Считаем агрегирующую оконную функцию в рамках клиента и месяца платежа, сортируем по дате платежа, чтобы посчитать накопительный итог по платежам
WITH 
MonthlyAgg AS (
    SELECT 
        client_id,
        pay_date,
        pay_sum,
        SUM(Ppay_sum) OVER (PARTITION BY client_id, DATE_TRUNC('month', pay_date) ORDER BY pay_date) AS running_total
    FROM payments
),
--Второй CTE. Считаем оконную функцию смещения, выводим предыдущий накопленный платеж в рамках клиента и месяца платежа, сортируем по дате платежа
WithPrevTotal AS (
    SELECT 
        client_id,
        pay_date,
        pay_sum,
        running_total,
        LAG(running_total) OVER (PARTITION BY client_id, DATE_TRUNC('month', pay_date) ORDER BY pay_date) AS prev_running_total
    FROM MonthlyAgg
)
--Основной запрос
SELECT 
    client_id AS "Идентификатор клиента",
    pay_date AS "Дата платежа",
    pay_sum AS "Сумма платежа",
    --Создаем условие
    CASE
	      --Если накопленная сумма меньше 400 000, выводим в коммиссию 0 
        WHEN running_total <= 400000 THEN 0
        ELSE (
            -- Иначе считаем комиссию за новые целые пакеты 100k, которые появились с последнего платежа. Округляем вверх
            (CEILING((running_total - 400000) / 100000) - 
             CEILING(COALESCE(GREATEST(prev_running_total - 400000, 0), 0) / 100000)) * 2000
             )
    END AS "comiss"
FROM WithPrevTotal
ORDER BY client_id, pay_date;
