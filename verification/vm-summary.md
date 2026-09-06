# Проверка на учебной ВМ

Сводка на 06.09.2026 составлена по выводу команд, присланному пользователем из SSH-сеанса. Это сводка, а не копия полных исходных журналов. Полные журналы находятся на ВМ в `~/dbops-lab/dbops-project/verification`.

## Подтверждено

- PostgreSQL 16.15, база store, роль store_migrator без SUPERUSER/CREATEDB/CREATEROLE.
- Flyway 10.20.1: V001, V002, V003, V004 выполнены успешно; success=t для всех четырёх записей истории.
- 6 товаров; 10 000 000 заказов; 10 000 000 позиций. Проверка строк и FK завершилась STAGE3_OK.
- V004: время миграции 02:48.253; индексы созданы; недельные результаты совпали, STAGE4_OK.
- Полный набор штатных тестов завершился PASS и AUTOTESTS_OK.

## Штатные тесты

| Группа | Успешные проверки |
| --- | --- |
| TestTask1 | database_is_alive; autotests_user_has_access; migrations_exists; check_if_schema_correct |
| TestTask2 | check_if_migration_change_schema_exists; check_if_schema_is_optimized; check_if_migration_insert_data_exists; check_if_data_exists_in_optimized_tables |
| TestTask3 | check_if_migration_create_index_exists; check_if_index_is_correct |

Время групп: 0.27 с, 41.50 с, 0.07 с соответственно. GitHub Actions пока не запускался.

## Совпавший результат запроса

Дата отсчёта: 2026-09-06. Интервал: [2026-08-24, 2026-08-31).

| Дата | Количество сосисок |
| --- | ---: |
| 2026-08-24 | 2834157 |
| 2026-08-25 | 2845719 |
| 2026-08-26 | 2813813 |
| 2026-08-27 | 2832011 |
| 2026-08-28 | 2826964 |
| 2026-08-29 | 2850239 |
| 2026-08-30 | 2834944 |

## Замеры

| Показатель | До индексов, мс | После индексов, мс |
| --- | ---: | ---: |
| SELECT, psql timing | 71722.071 | 64875.132 |
| EXPLAIN Execution Time | 50732.755 | 80486.756 |
| EXPLAIN, psql timing | 50757.785 | 80575.936 |

До: Seq Scan orders и order_product, Hash Join. После: Index Only Scan orders_date_created_id_idx с Heap Fetches=216027, Seq Scan order_product, Hash Join. В обоих планах 777617 строк соединения, 8 batches и temp read/written=41439 блоков. Устойчивое ускорение не подтверждено; результаты одиночных запусков разнонаправлены.
