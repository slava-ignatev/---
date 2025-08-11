
-- Создаем временную таблицу
WITH cte AS (
SELECT 
-- Округляем даты до начала месяца
	DATE_TRUNC('month', calendar_date)::DATE AS date,
--Считаем общее количество активных клиентов и валютных клиентов
	COUNT(DISTINCT client_id) FILTER (WHERE a.close_date IS NULL) AS count_active_clients,
	COUNT(DISTINCT client_id) FILTER (WHERE a.val != 'RUB' AND a.close_date IS NULL) AS count_active_currency_clients
FROM calendar c
-- Джойним через LEFT таблицу с клиентами по датам. 
-- Логика: дата открытия счета меньше или равна числу в календаре. И счет закрыт позднее или не закрыт
LEFT JOIN accounts a ON a.open_date<=c.calendar_date 
	AND (a.close_date>=c.calendar_date OR a.close_date IS NULL)
--Фильтруем в календаре только первые числа через извлечение первого числа из даты
WHERE EXTRACT(DAY FROM Сalendar_date) = 01
GROUP BY date
)

--Считаем результирующий запрос. Из сформированной CTE для каждой даты считаем долю клиентов с активными валютными счетами
-- Округляем через ROUND, CASE защищает от нулевых значений
SELECT 
	date,
	CASE 
    	WHEN count_active_clients = 0 OR count_active_currency_clients = 0 THEN 0.00
    	ELSE ROUND(count_active_currency_clients * 100.0 / count_active_clients, 2)
	END AS 'Доля активных валютных клиентов, %'
FROM cte