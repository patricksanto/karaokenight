# Karaoke Party — plano de desenvolvimento local

Status: guia operacional para construir a primeira versão local do projeto a partir de `KARAOKE_SPEC.md`.

Escopo deste documento: desenvolvimento, execução e validação local. Deploy, Railway, domínio, HTTPS público e provisionamento de infraestrutura ficam fora deste plano por enquanto.

## 1. Objetivo local

Construir uma versão P0 funcional do Karaoke Party para rodar em uma máquina de desenvolvimento e ser testada com navegador desktop e celulares na mesma rede local.

A versão local precisa permitir:

- Criar uma sala de karaokê.
- Entrar na sala por código ou QR code.
- Criar identidade de participante com apelido e emoji.
- Pedir músicas com título e artista.
- Organizar uma fila justa.
- Operar a apresentação pelo painel do anfitrião.
- Votar de 0 a 10, com mensagem opcional.
- Revelar resultado, votos agregados e mensagens anônimas.
- Exibir uma tela pública para projetor.
- Recuperar estado após refresh, reconexão e reinício simples do servidor local.

## 2. Estado atual do projeto

O repositório já contém um aplicativo Rails inicial. Não criar outro app dentro deste diretório.

Configuração observada:

- Ruby: `3.3.6`, definido em `.ruby-version`.
- Rails: `~> 8.1.3`, definido no `Gemfile`.
- Banco local: SQLite, em `storage/development.sqlite3`.
- Testes: Minitest padrão do Rails, com Capybara e Selenium para system tests.
- Frontend: ERB, Turbo, Stimulus, Importmap e Propshaft.
- Jobs: `solid_queue`.
- Cache: `solid_cache`.
- Action Cable: `async` em desenvolvimento e `solid_cable` em produção.
- Comando local atual: `bin/dev`, que executa `bin/rails server`.

Decisão para desenvolvimento local agora:

- Manter SQLite local para acelerar a implementação inicial.
- Manter Rails monolítico com ERB, Turbo e Stimulus.
- Usar `solid_queue` para jobs de finalização de votação.
- Usar Action Cable em desenvolvimento com o adapter atual, aceitando que ele roda no processo local do servidor.
- Não trocar para PostgreSQL/Redis enquanto o foco for apenas desenvolvimento local.
- Não configurar Railway neste momento.

## 3. Dependências locais necessárias

Instalar ou validar na máquina:

- Ruby `3.3.6`.
- Bundler compatível com o lockfile.
- SQLite 3.
- Navegador desktop moderno.
- Chrome ou Chromium para system tests com Selenium.
- Git.

Comandos úteis de verificação:

```sh
ruby --version
bundle --version
sqlite3 --version
bin/rails --version
```

## 4. Comandos de setup local

Instalar gems:

```sh
bundle install
```

Preparar banco local:

```sh
bin/rails db:prepare
```

Rodar servidor local:

```sh
bin/dev
```

Abrir no navegador:

```text
http://localhost:3000
```

Rodar console Rails:

```sh
bin/rails console
```

Rodar testes:

```sh
bin/rails test
bin/rails test:system
```

Rodar verificações estáticas disponíveis:

```sh
bin/rubocop
bin/brakeman
bin/bundler-audit
```

## 5. Variáveis de ambiente locais

Para a primeira versão local, evitar dependências obrigatórias de variáveis externas.

Variáveis opcionais úteis:

| Variável | Uso local |
| --- | --- |
| `RAILS_ENV` | Normalmente omitida; Rails usa `development` por padrão. |
| `HOST_URL` | URL base para QR code quando testar com celulares na rede local. |
| `JOB_CONCURRENCY` | Quantidade de processos do `solid_queue`, se o worker for executado separado. |

Ao testar com celulares, usar o IP da máquina na rede local em vez de `localhost`:

```text
http://SEU_IP_LOCAL:3000
```

O QR code deve apontar para a URL acessível pelo celular, não para `localhost`.

## 6. Processos locais

Modo mínimo para começar:

- Rodar `bin/dev`.
- Usar o processo Rails para desenvolver telas, controllers, modelos e Action Cable local.

Quando os jobs de finalização automática forem implementados, validar se eles estão sendo executados no ambiente local. Se necessário, ajustar `bin/dev` para iniciar também o worker do `solid_queue`.

Comando esperado para worker, se for executado separadamente:

```sh
bin/jobs
```

Critério: uma apresentação em estado `closing` precisa ser finalizada mesmo sem ação manual extra do anfitrião, respeitando `voting_closes_at`.

## 7. Entidades principais

Implementar somente o necessário para P0.

### Room

Responsável por representar a sala da festa.

Campos esperados:

- `code`: código curto público, único entre salas abertas.
- `name`: nome opcional da sala.
- `status`: `open` ou `closed`.
- `host_token_digest`: credencial protegida do anfitrião.
- Configurações ajustáveis, se necessário, com padrões simples.

Regras:

- Código público não autentica anfitrião.
- QR code usa apenas a entrada pública da sala.
- Sala fechada não aceita novos pedidos, votos ou entrada de participantes.

### Participant

Responsável pela identidade de quem participa da sala.

Campos esperados:

- `room_id`.
- `nickname`.
- `emoji`.
- `session_token_digest` ou identificador seguro equivalente.
- `available`: boolean.
- `revoked_at`: para moderação.

Regras:

- Apelido obrigatório, entre 2 e 24 caracteres.
- Apelido único por sala, ignorando maiúsculas e espaços nas pontas.
- Emoji obrigatório ou preenchido por padrão.
- Identidade persistida no navegador por cookie assinado/seguro.
- Digitar o mesmo apelido em outro dispositivo não assume a identidade existente.

### SongRequest

Responsável pelo pedido de música.

Campos esperados:

- `room_id`.
- `participant_id`.
- `title`.
- `artist`.
- `status`: `queued`, `performing`, `completed` ou `cancelled`.
- `manual_position` ou mecanismo equivalente apenas se necessário para override do anfitrião.

Regras:

- Título e artista obrigatórios, até 120 caracteres cada.
- No máximo 2 pedidos pendentes por participante.
- Impedir pedido idêntico pendente da mesma pessoa.
- Pessoas diferentes podem pedir a mesma música.

### SongRequestSinger

Responsável por ligar pedido e cantor.

No P0, cada pedido tem um cantor. A tabela prepara a expansão futura para duetos sem implementar duetos agora.

### Performance

Responsável pela apresentação em andamento ou concluída.

Campos esperados:

- `room_id`.
- `song_request_id`.
- `status`: `performing`, `closing`, `revealed` ou `aborted`.
- `started_at`.
- `voting_closes_at`.
- `revealed_at`.
- `average_score` congelada.
- `votes_count` congelado.
- `messages_order` ou campo equivalente para fixar ordem embaralhada das mensagens reveladas.

Regras:

- Só pode existir uma apresentação `performing` ou `closing` por sala.
- Transições precisam ser idempotentes.
- Resultado é congelado na revelação.

### PerformanceSinger

Snapshot dos cantores no início da apresentação.

Regras:

- Cantores não podem votar na própria apresentação.
- O snapshot não muda se o participante for editado depois.

### PerformanceVoter

Snapshot dos votantes elegíveis no início da apresentação.

Regras:

- Participantes que entram depois votam apenas na próxima apresentação.
- Participantes removidos perdem direito de votar dali em diante.

### Vote

Responsável pelo voto e mensagem.

Campos esperados:

- `performance_id`.
- `participant_id`.
- `score`: inteiro de 0 a 10.
- `message`: texto opcional de até 140 caracteres.
- `hidden_at`: moderação da mensagem.

Regras:

- Um voto por participante por apresentação.
- Voto repetido atualiza o voto existente enquanto o prazo estiver aberto.
- Mensagem pública é anônima na experiência, mas o banco mantém relação técnica.
- Ocultar mensagem não altera nota.

## 8. Serviços de domínio

Manter regras críticas fora de controllers grandes.

Serviços sugeridos:

- `QueueOrder`: calcula a fila prevista.
- `StartPerformance`: inicia apresentação em transação.
- `ClosePerformance`: muda apresentação para `closing` e define prazo final.
- `FinalizePerformance`: fecha votação, congela resultado e revela.
- `AbortPerformance`: aborta apresentação e cancela pedido correspondente.
- `CastVote`: cria ou atualiza voto com validações de elegibilidade.

Cada serviço deve:

- Receber objetos já autorizados quando possível.
- Usar transação para mutações críticas.
- Revalidar estado dentro da transação.
- Retornar erro previsível para a interface, sem depender de exceções genéricas para fluxo normal.

## 9. Rotas locais necessárias

Rotas públicas:

- Página inicial com criação ou entrada em sala.
- Entrada por código da sala.
- Cadastro de participante na sala.
- Tela do participante.
- Tela pública do projetor.

Rotas do participante:

- Criar pedido de música.
- Cancelar próprio pedido pendente.
- Marcar indisponível.
- Marcar disponível.
- Votar ou editar voto.

Rotas do anfitrião:

- Criar sala.
- Acessar painel com token/credencial de host.
- Iniciar apresentação.
- Encerrar música.
- Abortar apresentação.
- Escolher próximo pedido manualmente.
- Marcar participante indisponível.
- Remover participante.
- Ocultar mensagem.
- Fechar sala.

Rotas de leitura/snapshots:

- Snapshot da sala para participante.
- Snapshot da sala para anfitrião.
- Snapshot público para projetor.

## 10. Telas necessárias

### Entrada

Deve permitir:

- Criar sala como anfitrião.
- Entrar em sala existente por código.
- Exibir erros claros para sala inexistente ou fechada.

### Participante

Navegação curta:

- `Palco`.
- `Fila`.
- `Minhas músicas`.

A tela deve mostrar:

- Estado atual da apresentação.
- Botão principal de voto quando elegível.
- Aviso quando o participante é o cantor.
- Aviso quando o participante é o próximo.
- Formulário de pedido de música.
- Pedidos próprios pendentes.
- Ação para passar a vez e voltar.

### Anfitrião

Deve mostrar:

- Código da sala.
- Link público e QR code.
- Link da tela do projetor.
- Música atual.
- Próximos da fila.
- Lista de pedidos.
- Participantes e disponibilidade.
- Controles de iniciar, encerrar, abortar e fechar sala.
- Mensagens reveladas com ação de ocultar.

### Projetor

Deve mostrar somente dados públicos:

- Código da sala e QR code.
- Cantor atual.
- Música atual.
- Próximo cantor.
- Estado da votação.
- Resultado revelado.
- Quantidade de votos.
- Mensagens anônimas não ocultas.
- Próximos três da fila.

Não enviar para o projetor:

- Notas individuais.
- Autoria dos votos.
- Token do anfitrião.
- Dados administrativos ocultos.

## 11. Regras da fila P0

Implementar a fila conforme a especificação base:

1. Considerar apenas pedidos pendentes de participantes disponíveis.
2. Considerar somente o pedido mais antigo de cada pessoa para a próxima posição.
3. Se houver alternativa, excluir quem cantou na última apresentação concluída.
4. Entre candidatos restantes, escolher quem tem menos apresentações concluídas na sala.
5. Desempatar por data de criação do pedido e depois por ID.
6. Para prever próximas posições, simular escolhas e repetir com pedidos restantes.

Comportamentos obrigatórios:

- Se só uma pessoa quiser cantar, permitir músicas consecutivas.
- Passar a vez preserva pedidos e remove da elegibilidade.
- Voltar deixa a pessoa elegível novamente.
- Pedido cancelado não entra na fila.
- Apresentação abortada não conta como apresentação concluída.
- A apresentação atual nunca muda por recálculo da fila.

## 12. Estados principais

Estados de sala:

- `open`.
- `closed`.

Estados de pedido:

- `queued`.
- `performing`.
- `completed`.
- `cancelled`.

Estados de apresentação:

- `performing`.
- `closing`.
- `revealed`.
- `aborted`.

Transições obrigatórias:

- Iniciar apresentação: `queued` -> `performing` no pedido e cria `Performance.performing`.
- Encerrar música: `performing` -> `closing` e define `voting_closes_at` no servidor.
- Finalizar votação: `closing` -> `revealed`, congela média, total e mensagens.
- Abortar: `performing` ou `closing` -> `aborted`, sem resultado público.
- Fechar sala: permitido apenas sem apresentação ativa; cancela pedidos pendentes.

## 13. Tempo real local

Usar Turbo Streams e Action Cable quando isso simplificar a experiência.

Eventos que devem atualizar telas:

- Novo participante.
- Mudança de disponibilidade.
- Novo pedido.
- Pedido cancelado.
- Fila recalculada.
- Apresentação iniciada.
- Apresentação encerrada.
- Resultado revelado.
- Mensagem ocultada.
- Sala fechada.

Cada tela deve conseguir recuperar estado completo com refresh. Não depender apenas de eventos recebidos em tempo real.

## 14. Segurança local essencial

Mesmo em desenvolvimento local, implementar as regras como se fossem reais:

- Autorizar toda mutação no servidor.
- Nunca confiar em `participant_id` vindo do formulário para voto ou pedido.
- Isolar dados por sala em todas as queries.
- Proteger ação de anfitrião com token/credencial própria.
- Não colocar token do anfitrião no QR code.
- Escapar texto de usuário em nomes, músicas e mensagens.
- Validar tamanho e formato no servidor.
- Impedir voto do cantor por regra de servidor.
- Não enviar notas individuais para participante comum ou projetor.

## 15. Dados de desenvolvimento

Criar seeds somente para `development` e `test`, se forem úteis.

Seeds locais podem criar:

- Uma sala aberta.
- Um anfitrião com token impresso no log ou documentado de forma local.
- Participantes fictícios: Ana, Bruno e Carla.
- Pedidos de exemplo: A1/A2, B1 e C1.

Não depender dos seeds para o fluxo principal funcionar.

## 16. Plano de implementação local

### Fase 0 — base

- [ ] Confirmar que `bundle install` roda sem erro.
- [ ] Confirmar que `bin/rails db:prepare` roda sem erro.
- [ ] Confirmar que `bin/dev` sobe a aplicação.
- [ ] Definir página inicial temporária ou definitiva.
- [ ] Criar registro de progresso em arquivo separado, se necessário.

### Fase 1 — sala e identidade

- [ ] Criar modelos e migrations de sala e participante.
- [ ] Criar fluxo de criação de sala.
- [ ] Gerar código público curto da sala.
- [ ] Gerar credencial segura do anfitrião.
- [ ] Criar entrada por código.
- [ ] Criar identidade persistente de participante.
- [ ] Validar apelido único por sala.
- [ ] Separar autorização de participante, anfitrião e projetor.

### Fase 2 — pedidos e fila

- [ ] Criar modelos de pedido e cantor do pedido.
- [ ] Criar formulário de pedido.
- [ ] Validar título, artista, duplicidade e limite de dois pedidos.
- [ ] Implementar cancelamento de pedido próprio.
- [ ] Implementar disponibilidade do participante.
- [ ] Implementar `QueueOrder`.
- [ ] Mostrar fila prevista para participante, host e projetor.
- [ ] Implementar override manual do próximo pelo anfitrião, se necessário para P0.

### Fase 3 — apresentação

- [ ] Criar modelos de apresentação, cantor da apresentação e votante elegível.
- [ ] Implementar `StartPerformance`.
- [ ] Impedir duas apresentações ativas na mesma sala.
- [ ] Mostrar apresentação atual nas três interfaces.
- [ ] Implementar `ClosePerformance` com prazo de 10 segundos.
- [ ] Implementar job ou mecanismo local de finalização.
- [ ] Implementar recuperação de apresentação com prazo vencido.

### Fase 4 — votos e resultado

- [ ] Criar modelo de voto.
- [ ] Implementar `CastVote`.
- [ ] Permitir voto inteiro de 0 a 10.
- [ ] Permitir mensagem opcional até 140 caracteres.
- [ ] Permitir edição até o prazo final.
- [ ] Bloquear voto do cantor.
- [ ] Implementar `FinalizePerformance`.
- [ ] Congelar média, total e ordem das mensagens.
- [ ] Mostrar resultado no participante, host e projetor.
- [ ] Implementar ocultar mensagem pelo anfitrião.

### Fase 5 — experiência local

- [ ] Melhorar layout mobile.
- [ ] Melhorar tela de projetor em desktop.
- [ ] Gerar QR code local.
- [ ] Testar com celulares na mesma rede.
- [ ] Ajustar feedback visual de carregamento e erro.
- [ ] Garantir refresh e reconexão com estado correto.

### Fase 6 — testes críticos

- [ ] Testar regra de fila em models/services.
- [ ] Testar transições de apresentação.
- [ ] Testar voto e bloqueio de cantor.
- [ ] Testar finalização idempotente.
- [ ] Testar isolamento entre salas.
- [ ] Testar HTML escapado em apelidos, músicas e mensagens.
- [ ] Testar fluxo completo com system test ou ensaio manual documentado.

## 17. Critérios de aceite local

A versão local P0 só deve ser considerada pronta quando:

- Uma sala pode ser criada do zero.
- Um convidado entra por código ou QR code.
- A identidade volta ao atualizar o navegador.
- Três participantes conseguem pedir músicas.
- A fila segue o exemplo Ana A1/A2, Bruno B1, Carla C1: A1, B1, C1, A2.
- O anfitrião inicia e encerra uma apresentação.
- O cantor não consegue votar, inclusive por requisição manipulada.
- Participantes elegíveis votam e podem editar o voto antes do prazo.
- A finalização revela média com uma casa decimal e total de votos.
- Nenhum voto mostra mensagem adequada sem nota numérica.
- Mensagens aparecem anônimas e podem ser ocultadas pelo host.
- Projetor não recebe dados privados.
- Refresh em participante, host e projetor recupera estado correto.
- Testes automatizados críticos passam localmente.

## 18. Ensaio local recomendado

Executar antes de considerar a versão usável em festa:

1. Iniciar `bin/dev`.
2. Abrir host em uma janela normal.
3. Abrir projetor em outra janela.
4. Entrar como três participantes usando celulares ou perfis diferentes do navegador.
5. Criar dois pedidos por pessoa.
6. Conferir a ordem da fila.
7. Iniciar apresentação da primeira pessoa.
8. Confirmar que o cantor não vê formulário de voto.
9. Votar com os outros participantes.
10. Encerrar música e aguardar a revelação automática.
11. Conferir média, total e mensagens.
12. Ocultar uma mensagem e conferir atualização no projetor.
13. Marcar participante como indisponível e conferir recálculo da fila.
14. Atualizar todas as páginas e confirmar estado preservado.
15. Reiniciar o servidor durante uma apresentação em `closing` e confirmar recuperação possível.

## 19. Fora do plano local atual

Não implementar agora:

- Deploy no Railway.
- PostgreSQL obrigatório para desenvolvimento local.
- Redis obrigatório para desenvolvimento local.
- Autenticação social.
- Integração com Singa.
- Scraping, áudio, vídeo ou sincronização automática.
- Duetos.
- Ranking competitivo.
- Reações ao vivo.
- Dedicatórias.
- Desafios.
- Prêmios.
- Aplicativo nativo.

## 20. Próximo passo sugerido

Começar pela Fase 0 e Fase 1, mantendo commits ou mudanças pequenas e verificáveis. A primeira entrega útil deve ser: criar sala, entrar como participante, manter identidade por sessão e abrir uma tela pública de projetor vazia, mas autorizada corretamente.
