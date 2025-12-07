psql:/mnt/c/Users/levi/programming/DB-course-SI/lab4/lab4.sql:18: NOTICE:  relation "idx_content_items_type_year" already exists, skipping
CREATE INDEX
                                                     QUERY PLAN
---------------------------------------------------------------------------------------------------------------------
 Sort  (cost=1.11..1.12 rows=1 width=530) (actual time=0.029..0.030 rows=2 loops=1)
   Sort Key: release_year DESC
   Sort Method: quicksort  Memory: 25kB
   ->  Seq Scan on content_items  (cost=0.00..1.10 rows=1 width=530) (actual time=0.009..0.011 rows=2 loops=1)
         Filter: ((release_year >= 2000) AND (release_year <= 2020) AND (content_type = 'MOVIE'::content_type_enum))
         Rows Removed by Filter: 4
 Planning Time: 0.099 ms
 Execution Time: 0.047 ms
(8 rows)

логика индекса правильная, но на маленьких объёмах данных PostgreSQL его даже не пытается использовать.



 До индекса (первая версия плана)                        QUERY PLAN
---------------------------------------------------------------------------------------------------------------
 Sort  (cost=1.08..1.09 rows=1 width=562) (actual time=0.022..0.022 rows=6 loops=1)
   Sort Key: title
   Sort Method: quicksort  Memory: 25kB
   ->  Seq Scan on content_items  (cost=0.00..1.07 rows=1 width=562) (actual time=0.005..0.006 rows=6 loops=1)
         Filter: ((language)::text = 'en'::text)
 Planning Time: 0.083 ms
 Execution Time: 0.032 ms
(7 rows)

psql:/mnt/c/Users/levi/programming/DB-course-SI/lab4/lab4.sql:39: NOTICE:  relation "idx_content_items_lang_title" already exists, skipping
CREATE INDEX

После CREATE INDEX idx_content_items_lang_title            QUERY PLAN
---------------------------------------------------------------------------------------------------------------
 Sort  (cost=1.08..1.09 rows=1 width=562) (actual time=0.019..0.019 rows=6 loops=1)
   Sort Key: title
   Sort Method: quicksort  Memory: 25kB
   ->  Seq Scan on content_items  (cost=0.00..1.07 rows=1 width=562) (actual time=0.008..0.010 rows=6 loops=1)
         Filter: ((language)::text = 'en'::text)
 Planning Time: 0.068 ms
 Execution Time: 0.033 ms
(7 rows)

запрос идеально подходит под композитный индекс, но из-за микроскопического объёма таблицы дешевле просто прочитать все строки и отсортировать.


                                               QUERY PLAN
---------------------------------------------------------------------------------------------------------
 Seq Scan on content_items  (cost=0.00..1.07 rows=1 width=524) (actual time=0.010..0.011 rows=1 loops=1)
   Filter: ((title)::text ~~ 'The%'::text)
   Rows Removed by Filter: 5
 Planning Time: 0.110 ms
 Execution Time: 0.024 ms
(5 rows)

psql:/mnt/c/Users/levi/programming/DB-course-SI/lab4/lab4.sql:57: NOTICE:  relation "idx_content_items_title_prefix" already exists, skipping
CREATE INDEX
                                               QUERY PLAN
---------------------------------------------------------------------------------------------------------
 Seq Scan on content_items  (cost=0.00..1.07 rows=1 width=524) (actual time=0.007..0.008 rows=1 loops=1)
   Filter: ((title)::text ~~ 'The%'::text)
   Rows Removed by Filter: 5
 Planning Time: 0.044 ms
 Execution Time: 0.018 ms
(5 rows)

Execution Time немного упал: 0.024 → 0.018 ms, но это из-за кэша/разброса, а не смены стратегии.    



                                                       QUERY PLAN
------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=2.22..2.23 rows=1 width=526) (actual time=0.070..0.071 rows=3 loops=1)
   Sort Key: r.score DESC
   Sort Method: quicksort  Memory: 25kB
   ->  Hash Join  (cost=1.12..2.21 rows=1 width=526) (actual time=0.059..0.061 rows=3 loops=1)
         Hash Cond: (ci.content_id = r.content_id)
         ->  Seq Scan on content_items ci  (cost=0.00..1.06 rows=6 width=524) (actual time=0.008..0.009 rows=6 loops=1)
         ->  Hash  (cost=1.11..1.11 rows=1 width=10) (actual time=0.016..0.016 rows=3 loops=1)
               Buckets: 1024  Batches: 1  Memory Usage: 9kB
               ->  Seq Scan on ratings r  (cost=0.00..1.11 rows=1 width=10) (actual time=0.003..0.004 rows=3 loops=1)
                     Filter: (user_id = 1)
                     Rows Removed by Filter: 6
 Planning Time: 0.355 ms
 Execution Time: 0.095 ms
(13 rows)

psql:/mnt/c/Users/levi/programming/DB-course-SI/lab4/lab4.sql:75: NOTICE:  relation "idx_ratings_user" already exists, skipping
CREATE INDEX
                                                       QUERY PLAN
------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=2.22..2.23 rows=1 width=526) (actual time=0.038..0.039 rows=3 loops=1)
   Sort Key: r.score DESC
   Sort Method: quicksort  Memory: 25kB
   ->  Hash Join  (cost=1.12..2.21 rows=1 width=526) (actual time=0.029..0.031 rows=3 loops=1)
         Hash Cond: (ci.content_id = r.content_id)
         ->  Seq Scan on content_items ci  (cost=0.00..1.06 rows=6 width=524) (actual time=0.005..0.006 rows=6 loops=1)
         ->  Hash  (cost=1.11..1.11 rows=1 width=10) (actual time=0.014..0.014 rows=3 loops=1)
               Buckets: 1024  Batches: 1  Memory Usage: 9kB
               ->  Seq Scan on ratings r  (cost=0.00..1.11 rows=1 width=10) (actual time=0.003..0.003 rows=3 loops=1)
                     Filter: (user_id = 1)
                     Rows Removed by Filter: 6
 Planning Time: 0.124 ms
 Execution Time: 0.057 ms
(13 rows)

индекс idx_ratings_user корректен, но пока таблица маленькая, оптимизатор предпочитает полный скан.




                                                             QUERY PLAN
------------------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=2.48..2.49 rows=6 width=564) (actual time=0.097..0.098 rows=6 loops=1)
   Sort Key: (avg(r.score)) DESC NULLS LAST
   Sort Method: quicksort  Memory: 25kB
   ->  HashAggregate  (cost=2.33..2.40 rows=6 width=564) (actual time=0.045..0.047 rows=6 loops=1)
         Group Key: ci.content_id
         Batches: 1  Memory Usage: 24kB
         ->  Hash Right Join  (cost=1.14..2.26 rows=9 width=526) (actual time=0.032..0.037 rows=9 loops=1)
               Hash Cond: (r.content_id = ci.content_id)
               ->  Seq Scan on ratings r  (cost=0.00..1.09 rows=9 width=10) (actual time=0.002..0.003 rows=9 loops=1)
               ->  Hash  (cost=1.06..1.06 rows=6 width=524) (actual time=0.020..0.021 rows=6 loops=1)
                     Buckets: 1024  Batches: 1  Memory Usage: 9kB
                     ->  Seq Scan on content_items ci  (cost=0.00..1.06 rows=6 width=524) (actual time=0.006..0.007 rows=6 loops=1)
 Planning Time: 0.158 ms
 Execution Time: 0.128 ms
(14 rows)

                                                                QUERY PLAN
------------------------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=78.10..78.25 rows=60 width=234) (actual time=0.115..0.117 rows=4 loops=1)
   Sort Key: (count(ci.content_id)) DESC
   Sort Method: quicksort  Memory: 25kB
   ->  HashAggregate  (cost=75.73..76.33 rows=60 width=234) (actual time=0.084..0.086 rows=4 loops=1)
         Group Key: u.user_id
         Batches: 1  Memory Usage: 24kB
         ->  Hash Right Join  (cost=28.10..66.48 rows=1850 width=234) (actual time=0.071..0.079 rows=8 loops=1)
               Hash Cond: (c.user_id = u.user_id)
               ->  Hash Right Join  (cost=16.75..50.17 rows=1850 width=16) (actual time=0.036..0.041 rows=7 loops=1)
                     Hash Cond: (ci.collection_id = c.collection_id)
                     ->  Seq Scan on collection_items ci  (cost=0.00..28.50 rows=1850 width=16) (actual time=0.002..0.002 rows=7 loops=1)
                     ->  Hash  (cost=13.00..13.00 rows=300 width=16) (actual time=0.018..0.018 rows=3 loops=1)
                           Buckets: 1024  Batches: 1  Memory Usage: 9kB
                           ->  Seq Scan on collections c  (cost=0.00..13.00 rows=300 width=16) (actual time=0.002..0.003 rows=3 loops=1)
               ->  Hash  (cost=10.60..10.60 rows=60 width=226) (actual time=0.022..0.022 rows=4 loops=1)
                     Buckets: 1024  Batches: 1  Memory Usage: 9kB
                     ->  Seq Scan on users u  (cost=0.00..10.60 rows=60 width=226) (actual time=0.008..0.008 rows=4 loops=1)
 Planning Time: 0.398 ms
 Execution Time: 0.176 ms
(19 rows)

                                                               QUERY PLAN
-----------------------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=45.53..45.68 rows=60 width=242) (actual time=0.107..0.108 rows=4 loops=1)
   Sort Key: (count(DISTINCT r.content_id)) DESC, (count(DISTINCT l.list_id)) DESC
   Sort Method: quicksort  Memory: 25kB
   ->  GroupAggregate  (cost=38.74..43.76 rows=60 width=242) (actual time=0.097..0.104 rows=4 loops=1)
         Group Key: u.user_id
         ->  Merge Left Join  (cost=38.74..40.91 rows=300 width=242) (actual time=0.064..0.068 rows=10 loops=1)
               Merge Cond: (u.user_id = r.user_id)
               ->  Sort  (cost=37.50..38.25 rows=300 width=234) (actual time=0.052..0.053 rows=4 loops=1)
                     Sort Key: u.user_id
                     Sort Method: quicksort  Memory: 25kB
                     ->  Hash Right Join  (cost=11.35..25.16 rows=300 width=234) (actual time=0.043..0.046 rows=4 loops=1)
                           Hash Cond: (l.user_id = u.user_id)
                           ->  Seq Scan on lists l  (cost=0.00..13.00 rows=300 width=16) (actual time=0.003..0.004 rows=3 loops=1)
                           ->  Hash  (cost=10.60..10.60 rows=60 width=226) (actual time=0.031..0.031 rows=4 loops=1)
                                 Buckets: 1024  Batches: 1  Memory Usage: 9kB
                                 ->  Seq Scan on users u  (cost=0.00..10.60 rows=60 width=226) (actual time=0.006..0.007 rows=4 loops=1)
               ->  Sort  (cost=1.23..1.26 rows=9 width=16) (actual time=0.011..0.011 rows=9 loops=1)
                     Sort Key: r.user_id
                     Sort Method: quicksort  Memory: 25kB
                     ->  Seq Scan on ratings r  (cost=0.00..1.09 rows=9 width=16) (actual time=0.002..0.003 rows=9 loops=1)
 Planning Time: 0.249 ms
 Execution Time: 0.152 ms
(22 rows)


запрос с COUNT(DISTINCT ...) и несколькими JOIN реализуется комбинацией сортировок + merge join + group aggregate. Опять же, на таком размере таблиц всё работает за ~0.15 ms, без необходимости лезть в индексы.