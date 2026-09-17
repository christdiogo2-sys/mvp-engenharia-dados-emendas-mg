# Documentação do MVP: Pipeline de Dados de Emendas Parlamentares (MG)

## Contexto de Negócios e Perguntas (Etapa 2 e 4.1)

O objetivo deste projeto é analisar a distribuição e a execução financeira das Emendas Parlamentares destinadas ao estado de Minas Gerais. O pipeline de dados foi construído para transformar registros governamentais brutos em insights estruturados, permitindo entender como os recursos públicos são alocados e executados.

Os dados brutos foram extraídos do Portal da Transparência do Governo Federal (Visão Geral de Emendas Parlamentares). Trata-se de uma base de dados governamental regida pela licença de Dados Abertos, permitindo o livre uso, cruzamento e análise para fins acadêmicos e informativos.

As perguntas de negócio que guiam o desenvolvimento deste pipeline são:

1. Quais são os 5 municípios mineiros que receberam o maior volume financeiro de emendas pagas?
2. Qual partido político apresenta a maior proporção entre valor empenhado e valor pago para o estado de Minas Gerais?
3. Existe uma concentração de repasses financeiros em áreas de atuação específicas (como Saúde ou Educação)?

## Carga dos Dados (Etapa 4.2)

A ingestão inicial ocorreu de forma manual, dadas as limitações do escopo do MVP. O arquivo CSV consolidado do ano selecionado foi baixado do Portal da Transparência e inserido no ambiente de nuvem do Databricks Free Edition.

Durante a carga para a criação da tabela base (`bronze_emendas_raw`), o delimitador de colunas foi configurado para ponto e vírgula (`;`) e a primeira linha foi definida como cabeçalho para garantir a correta identificação dos metadados. O armazenamento subjacente utiliza o formato Delta Lake nativo da plataforma.

*[Inserir Screenshot: Tabela bronze_emendas_raw no Catalog do Databricks]*
**Referência do script:** [Inserir link do Github para o notebook SQL]

## Modelagem e Catálogo de Dados (Etapa 4.3)

Os dados foram modelados seguindo o modelo dimensional *Star Schema* (Esquema Estrela), visando otimizar a performance de consultas analíticas e separar os fatos numéricos das dimensões descritivas. O Unity Catalog (ou catálogo nativo do Databricks) foi utilizado para registrar as tabelas.

**Catálogo de Dados:**

| Tabela | Coluna | Tipo de Dado | Domínio / Valores | Descrição e Linhagem |
| --- | --- | --- | --- | --- |
| `fato_emendas_mg` | `id_emenda` | String | Alfanumérico | Código único da emenda. Origem: `Codigo_Emenda`. |
| `fato_emendas_mg` | `valor_empenhado` | Decimal | Valores $\ge 0.00$ | Montante reservado pelo governo. Origem: `Valor_Empenhado`. |
| `fato_emendas_mg` | `valor_pago` | Decimal | Valores $\ge 0.00$ | Montante efetivamente pago. Origem: `Valor_Pago`. |
| `fato_emendas_mg` | `municipio` | String | Nomes de cidades de MG | Chave de ligação para destino. Origem: `Nome_Municipio`. |
| `dim_parlamentar` | `nome_parlamentar` | String | Texto | Nome do autor da emenda. Origem: `Nome_Parlamentar`. |
| `dim_parlamentar` | `partido` | String | Siglas partidárias válidas | Partido do autor. Origem: `Sigla_Partido`. |
| `dim_area_atuacao` | `area_atuacao` | String | Saúde, Educação, etc. | Setor de destino do recurso. Origem: `Funcao`. |

*[Inserir Screenshot: Esquema visual ou listagem de tabelas do catálogo no Databricks]*

## Pipeline de Dados (Etapa 4.4)

O processo de ETL (Extract, Transform, Load) foi orquestrado em um único Notebook no Databricks utilizando a linguagem SQL e organizado com base na Arquitetura Medalhão:

* **Camada Bronze:** Os dados foram mantidos em seu formato bruto e original (`bronze_emendas_raw`), preservando todo o histórico sem alterações para garantir a rastreabilidade.
* **Camada Silver:** Foi criada a tabela `silver_emendas_mg`. Nesta etapa, aplicou-se um filtro espacial restrito (`WHERE UF = 'MG'`). As colunas financeiras, originalmente strings com vírgulas, sofreram transformações de substituição de caracteres (`REPLACE`) e conversão de tipos (`CAST AS DECIMAL`) para permitir cálculos matemáticos.
* **Camada Gold:** A tabela Silver foi desnormalizada e dividida, gerando a tabela fato (`fato_emendas_mg`) e as dimensões descritivas (`dim_parlamentar`, `dim_area_atuacao`).

*[Inserir Screenshot: Células do Notebook rodando os comandos de CREATE TABLE]*
**Referência do script:** [Inserir link do Github para o notebook SQL]

## Qualidade de Dados (Etapa 4.5)

Antes da modelagem final, a qualidade dos atributos passou por verificações e tratamentos diretamente no código SQL da camada Silver:

* **Completude e Unicidade:** Identificaram-se emendas com o campo "Município" nulo, referentes a repasses de abrangência estadual. O tratamento adotado foi substituir valores nulos por "Abrangência Estadual" usando a função `COALESCE`, evitando a perda do registro financeiro.
* **Consistência:** Os campos de valores financeiros (`Valor_Empenhado`, `Valor_Pago`) apresentavam formatação em string com padrão brasileiro (vírgula para decimais). A tentativa de soma sem tratamento geraria erros. A consistência foi garantida transformando as vírgulas em pontos e realizando o *casting* para o tipo `DECIMAL(15,2)`.
* **Acurácia e Outliers:** Realizou-se uma verificação de valores negativos nos campos de repasse. Nenhuma anomalia de sinal negativo foi encontrada na base filtrada.

## Análise de Dados (Etapa 4.5)

Com os dados higienizados e modelados na camada Gold, as seguintes respostas foram extraídas via consultas SQL:

**1. Municípios com maior volume financeiro pago:**
As consultas evidenciaram que os municípios de [INSERIR CIDADE 1], [INSERIR CIDADE 2] e [INSERIR CIDADE 3] lideram o recebimento de repasses no estado. Isso sugere uma correlação entre o peso eleitoral e populacional dessas regiões e a destinação de emendas.
*[Inserir Screenshot: Resultado do SELECT Top 5 Municípios]*

**2. Proporção Empenhado vs. Pago por Partido:**
A análise de execução orçamentária revelou que o partido [INSERIR PARTIDO] obteve a maior taxa de conversão entre o valor que foi prometido (empenhado) e o que de fato chegou ao cofre (pago), atingindo uma proporção de [INSERIR PORCENTAGEM]%.
*[Inserir Screenshot: Resultado do SELECT calculando a proporção por partido]*

**3. Concentração por Área de Atuação:**
A área de [INSERIR ÁREA, ex: Saúde] domina amplamente os repasses, representando [INSERIR PORCENTAGEM]% do volume total pago para Minas Gerais, refletindo a prioridade dos parlamentares em direcionar recursos para o custeio da atenção básica e hospitalar local.
*[Inserir Screenshot: Resultado do SELECT agrupado por função/área]*

## Autoavaliação

O objetivo inicial do MVP foi concluído com êxito. Foi possível construir um pipeline funcional que partiu de uma necessidade de negócio clara (entender o fluxo das emendas parlamentares em MG) até a entrega de dados limpos e modelados em um ambiente de nuvem. A arquitetura Lakehouse do Databricks provou ser altamente eficiente, permitindo executar rotinas de *Data Warehousing* no mesmo local da ingestão bruta, tudo gerido por linguagem SQL.

A principal dificuldade técnica encontrada residiu na etapa de ETL da camada Silver, especificamente na identificação da melhor abordagem para tratar dados nulos e limpar strings monetárias oriundas do formato padrão brasileiro governamental.

Como trabalhos futuros para enriquecer este portfólio, planeja-se a automação da extração via consumo direto de APIs do Portal da Transparência — eliminando o upload manual de CSVs —, além da conexão da camada Gold com uma ferramenta de Business Intelligence, como o Power BI, para a construção de painéis dinâmicos de visualização de dados.
