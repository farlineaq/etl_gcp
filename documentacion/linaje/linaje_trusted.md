# Linaje de Datos

# Tablas

- [analytical_model](#analytical_model)
- [contactabilidad](#contactabilidad)
- [dim_modelo_segmento](#dim_modelo_segmento)
- [fact_months](#fact_months)
- [fact_target_days](#fact_target_days)
- [fact_target_months](#fact_target_months)
- [fact_target_years](#fact_target_years)
- [model_run](#model_run)
- [segmentacion](#segmentacion)

# analytical_model

| Mapeo de datos                              |                                                                                    |                  |                   |                  
|---------------------------------------------|------------------------------------------------------------------------------------|------------------|-------------------|
| Nombre del componente: Dataproc con PySpark |                                                                                    |                  |                   |                                                        
| Nombre Del destino: Capa de trusted         |                                                                                    |                  |                   |                                                           
| Enrutamiento: desde GCS a Dataproc          |                                                                                    |                  |                   |              
| Campo Destino                               | Transformación                                                                     | Origen           | Campo Origen      | 
| modelid                                     | No se realiza transformación                                                       | analytical_model | modelid           | 
| ModelDdesc                                  | No se realiza transformación                                                       | analytical_model | ModelDdesc        | 
| IndicadorAgregada                           | No se realiza transformación                                                       | analytical_model | IndicadorAgregada | 
| FechaActualización                          | Se agrega como columna nueva, Cambio del formato **UTC a UTC-5** en Colombian Time | Campo Calculado  |                   |

# contactabilidad

| Mapeo de datos                              |                                                                                    |                 |                     |
|---------------------------------------------|------------------------------------------------------------------------------------|-----------------|---------------------|
| Nombre del componente: Dataproc con PySpark |                                                                                    |                 |                     |
| Nombre Del destino: Capa de trusted         |                                                                                    |                 |                     |
| Enrutamiento: desde GCS a Dataproc          |                                                                                    |                 |                     |
| Campo Destino                               | Transformación                                                                     | Origen          | Campo Origen        |
| PartyId                                     | No se realiza transformación                                                       | contactabilidad | PartyId             |
| indicadoremail                              | No se realiza transformación                                                       | contactabilidad | indicadoremail      |
| indicadorcel                                | No se realiza transformación                                                       | contactabilidad | indicadorcel        |
| fechaindicadoremail                         | No se realiza transformación                                                       | contactabilidad | fechaindicadoremail |
| fechaindicadorcel                           | No se realiza transformación                                                       | contactabilidad | fechaindicadorcel   |
| FechaActualización                          | Se agrega como columna nueva, Cambio del formato **UTC a UTC-5** en Colombian Time | Campo Calculado |                     |

# dim_modelo_segmento

| Mapeo de datos                              |                                                                                    |                     |                   |
|---------------------------------------------|------------------------------------------------------------------------------------|---------------------|-------------------|
| Nombre del componente: Dataproc con PySpark |                                                                                    |                     |                   |
| Nombre Del destino: Capa de trusted         |                                                                                    |                     |                   |
| Enrutamiento: desde GCS a Dataproc          |                                                                                    |                     |                   |
| Campo Destino                               | Transformación                                                                     | Origen              | Campo Origen      |
| ModeloSegmentoid                            | No se realiza transformación                                                       | dim_modelo_segmento | ModeloSegmentoid  |
| Modelid                                     | No se realiza transformación                                                       | dim_modelo_segmento | Modelid           |
| ModelSegmentoDesc                           | No se realiza transformación                                                       | dim_modelo_segmento | ModelSegmentoDesc |
| FechaActualización                          | Se agrega como columna nueva, Cambio del formato **UTC a UTC-5** en Colombian Time | Campo Calculado     |                   |

# fact_months

| Mapeo de datos                              |                                                                                    |                 |               |
|---------------------------------------------|------------------------------------------------------------------------------------|-----------------|---------------|
| Nombre del componente: Dataproc con PySpark |                                                                                    |                 |               |
| Nombre Del destino: Capa de trusted         |                                                                                    |                 |               |
| Enrutamiento: desde GCS a Dataproc          |                                                                                    |                 |               |
| Campo Destino                               | Transformación                                                                     | Origen          | Campo Origen  |
| Actualizacion                               | No se realiza transformación                                                       | fact_months     | Actualizacion |
| Fecha                                       | No se realiza transformación                                                       | fact_months     | Fecha         |
| Cadena                                      | No se realiza transformación                                                       | fact_months     | Cadena        |
| CadenaId                                    | No se realiza transformación                                                       | fact_months     | CadenaId      |
| Indicador                                   | No se realiza transformación                                                       | fact_months     | Indicador     |
| IndicadorId                                 | No se realiza transformación                                                       | fact_months     | IndicadorId   |
| Valor                                       | No se realiza transformación                                                       | fact_months     | Valor         |
| FechaActualizacion                          | Se agrega como columna nueva, Cambio del formato **UTC a UTC-5** en Colombian Time | Campo Calculado |               |

trusted: Fecha CadenaId IndicadorId ModeloSegmentoId Valor FechaActualizacion
raw: Actualizacion Fecha Cadena CadenaId Indicador IndicadorId Valor

# fact_target_days

| Mapeo de datos                              |                                                                                    |                  |               |
|---------------------------------------------|------------------------------------------------------------------------------------|------------------|---------------|
| Nombre del componente: Dataproc con PySpark |                                                                                    |                  |               |
| Nombre Del destino: Capa de trusted         |                                                                                    |                  |               |
| Enrutamiento: desde GCS a Dataproc          |                                                                                    |                  |               |
| Campo Destino                               | Transformación                                                                     | Origen           | Campo Origen  |
|                                             | Se elimina columna "Actualización"                                                 | fact_target_days | Actualizacion |
| Fecha                                       | No se realiza transformación                                                       | fact_target_days | Fecha         |
|                                             | Se elimina columna "Cadena"                                                        | fact_target_days | Cadena        |
| CadenaId                                    | No se realiza transformación                                                       | fact_target_days | CadenaId      |
|                                             | Se elimina columna "Indicador"                                                     | fact_target_days | Indicador     |
| IndicadorId                                 | No se realiza transformación                                                       | fact_target_days | IndicadorId   |
| ModeloSegmentoId                            | Se agrega como columna nueva, toma como valor 0 para toda la columna               | Campo Calculado  |               |
| Valor                                       | No se realiza transformación                                                       | fact_target_days | Valor         |
| FechaActualizacion                          | Se agrega como columna nueva, Cambio del formato **UTC a UTC-5** en Colombian Time | Campo Calculado  |               |

# fact_target_months

| Mapeo de datos                              |                                                                                    |                  |               |
|---------------------------------------------|------------------------------------------------------------------------------------|------------------|---------------|
| Nombre del componente: Dataproc con PySpark |                                                                                    |                  |               |
| Nombre Del destino: Capa de trusted         |                                                                                    |                  |               |
| Enrutamiento: desde GCS a Dataproc          |                                                                                    |                  |               |
| Campo Destino                               | Transformación                                                                     | Origen           | Campo Origen  |
|                                             | Se elimina columna "Actualizacion"                                                 | campo_calculado  | Actualizacion |
| Fecha                                       | No se realiza transformación                                                       | fact_target_days | Fecha         |
|                                             | Se elimina columna "Cadena"                                                        | fact_target_days | Cadena        |
| Cadenaid                                    | No se realiza transformación                                                       | fact_target_days | CadenaId      |
|                                             | Se elimina columna "indicador"                                                     | fact_target_days | Indicador     |
| IndicadorId                                 | No se realiza transformación                                                       | fact_target_days | IndicadorId   |
| ModeloSegmentoId                            | Se agrega como columna nueva, toma como valor 0 para toda la columna               | Campo Calculado  |               |
| Valor                                       | No se realiza transformación                                                       | fact_target_days | Valor         |
| FechaActualizacion                          | Se agrega como columna nueva, Cambio del formato **UTC a UTC-5** en Colombian Time | Campo Calculado  |               |

# fact_target_years

| Mapeo de datos                              |                                                                                    |                   |               |
|---------------------------------------------|------------------------------------------------------------------------------------|-------------------|---------------|
| Nombre del componente: Dataproc con PySpark |                                                                                    |                   |               |
| Nombre Del destino: Capa de trusted         |                                                                                    |                   |               |
| Enrutamiento: desde GCS a Dataproc          |                                                                                    |                   |               |
| Campo Destino                               | Transformación                                                                     | Origen            | Campo Origen  |
|                                             | Se elimina columna "Actualizacion"                                                 | fact_target_years | Actualizacion |
| Fecha                                       | No se realiza transformación                                                       | fact_target_years | Fecha         |
|                                             | Se elimina columna "Cadena"                                                        | fact_target_years | Cadena        |
| Cadenaid                                    | No se realiza transformación                                                       | fact_target_years | CadenaId      |
|                                             | Se elimina columna "indicador"                                                     | fact_target_years | Indicador     |
| IndicadorId                                 | No se realiza transformación                                                       | fact_target_years | IndicadorId   |
| ModeloSegmentoId                            | Se agrega como columna nueva, toma como valor 0 para toda la columna               | Campo Calculado   |               |
| Valor                                       | No se realiza transformación                                                       | fact_target_years | Valor         |
| FechaActualizacion                          | Se agrega como columna nueva, Cambio del formato **UTC a UTC-5** en Colombian Time | Campo Calculado   |               |

# model_run

| Mapeo de datos                              |                                                                                    |                 |                         |
|---------------------------------------------|------------------------------------------------------------------------------------|-----------------|-------------------------|
| Nombre del componente: Dataproc con PySpark |                                                                                    |                 |                         |
| Nombre Del destino: Capa de trusted         |                                                                                    |                 |                         |
| Enrutamiento: desde GCS a Dataproc          |                                                                                    |                 |                         |
| Campo Destino                               | Transformación                                                                     | Origen          | Campo Origen            |
| Modelid                                     | No se realiza transformación                                                       | model_run       | Modelid                 |
| ModelRunid                                  | No se realiza transformación                                                       | model_run       | ModelRunid              |
| ModelRunDt                                  | No se realiza transformación                                                       | model_run       | ModelRunDt              |
| LoyalityProgramCD                           | No se realiza transformación                                                       | model_run       | LoyalityProgramCD       |
| ChainCD                                     | No se realiza transformación                                                       | model_run       | ChainCD                 |
| bolClifre                                   | No se realiza transformación                                                       | model_run       | bolClifre               |
| TipoSegmentacionCarulla                     | No se realiza transformación                                                       | model_run       | TipoSegmentacionCarulla |
| FechaActualizacion                          | Se agrega como columna nueva, Cambio del formato **UTC a UTC-5** en Colombian Time | Campo Calculado |                         |

# segmentacion

| Mapeo de datos                              |                                                                                    |                 |                   |
|---------------------------------------------|------------------------------------------------------------------------------------|-----------------|-------------------|
| Nombre del componente: Dataproc con PySpark |                                                                                    |                 |                   |
| Nombre Del destino: Capa de trusted         |                                                                                    |                 |                   |
| Enrutamiento: desde GCS a Dataproc          |                                                                                    |                 |                   |
| Campo Destino                               | Transformación                                                                     | Origen          | Campo Origen      |
| ModeloSegmentoid                            | No se realiza transformación                                                       | segmentacion    | ModeloSegmentoid  |
| Modelid                                     | No se realiza transformación                                                       | segmentacion    | Modelid           |
| ModelSegmentoDesc                           | No se realiza transformación                                                       | segmentacion    | ModelSegmentoDesc |
| FechaActualizacion                          | Se agrega como columna nueva, Cambio del formato **UTC a UTC-5** en Colombian Time | Campo Calculado |                   |
