# Karaoke Party — especificação e guia para o agente de IA

Status: briefing para implementação; nenhum aplicativo foi implementado ou validado por este documento.
Idioma da interface: português brasileiro. Nome provisório: Karaoke Party.

## 1. Objetivo

Construir um aplicativo Ruby on Rails para acompanhar uma noite de karaokê entre amigos, com entrada por QR code, fila justa, votação da plateia e mensagens anônimas. A música e as letras continuam em uma plataforma externa como Singa. O aplicativo não reproduz áudio, não detecta o fim da música e não avalia a voz.

A experiência lembra Jackbox: uma tela coletiva no projetor e um controle individual no celular. O anfitrião opera o Singa e informa manualmente quando cada apresentação começa e termina. Destino de hospedagem desejado: Railway.

O objetivo imediato é ter uma versão confiável para a festa na próxima semana. Priorizar o ciclo completo funcionando antes dos extras.

## 2. Instruções ao agente implementador

1. Leia este arquivo e as instruções existentes no repositório antes de editar.
2. Inspecione o projeto, suas versões, dependências, testes e alterações locais. Preserve o trabalho existente. Não gere outro aplicativo dentro de um aplicativo já existente.
3. Em projeto novo, proponha a combinação de Ruby/Rails compatível com o ambiente e fixe as versões escolhidas. Consulte a documentação oficial atual para dependências e Railway; este documento não fixa versões nem garante comandos atuais de infraestrutura.
4. Implemente as fases abaixo em ordem, com mudanças pequenas e verificáveis. Registre o progresso nas caixas deste arquivo ou em um arquivo de progresso separado.
5. Use os padrões propostos para decisões rotineiras. Não bloqueie o trabalho pedindo confirmação sobre cada detalhe visual ou técnico.
6. Se houver impedimento real, descreva o que tentou, a evidência e o que falta. Não declare funcionalidades, testes ou deploy como concluídos sem executá-los.
7. Prepare a configuração de deploy e um runbook. Este documento não é, isoladamente, autorização para criar recursos pagos, acessar contas ou publicar; siga a autorização da sessão em que estiver sendo usado.
8. Ao concluir, entregue código, comandos reais de execução, testes realizados, limitações e instruções operacionais da festa.

## 3. Escopo e prioridades

### P0 — necessário para a festa

- Sala com código curto e QR code.
- Participante com apelido e avatar emoji, sem cadastro por e-mail.
- Sessão persistente no mesmo navegador.
- Pedido de música com título e artista.
- Fila justa, controle de disponibilidade e ajustes pelo anfitrião.
- Início e encerramento manual de apresentações.
- Votação de 0 a 10, sem voto do cantor.
- Mensagem opcional junto do voto e frases prontas.
- Revelação da média, quantidade de votos e mensagens anônimas.
- Interfaces para participante, anfitrião e projetor.
- Atualizações em tempo real e recuperação após reconexão.
- Moderação de mensagens e isolamento entre salas.
- Preparação de deploy no Railway e roteiro de ensaio.

### P1 — após validar P0

- Duetos com convite e aceite do segundo cantor.
- Reações ao vivo com limitação de frequência.
- Dedicatória no pedido.
- Histórico de apresentações e notas.

### P2 — evolução, sem atrasar a primeira versão

- Desafiar um amigo com sugestão de música e aceite.
- Plateia escolher a música do próximo cantor entre opções aprovadas por ele.
- Rodadas temáticas.
- Prêmios da noite por votação.
- Ranking competitivo opcional.
- Foto de perfil, se realmente necessária.

### Fora do escopo inicial

Integração automática ou scraping do Singa, sincronização com áudio, reconhecimento de voz, avaliação técnica de afinação, streaming de música, pagamentos, aplicativos nativos e autenticação social.

## 4. Padrões de produto adotados

Estes valores são propostas para começar a implementação, não decisões explícitas adicionais do usuário. Mantenha-os fáceis de ajustar.

| Item | Padrão |
| --- | --- |
| Clima | Descontraído, competição leve; ranking desativado |
| Identidade | Apelido de 2–24 caracteres e emoji |
| Código da sala | 6 caracteres sem símbolos ambíguos, único entre salas ativas |
| Pedidos pendentes | Até 2 por pessoa |
| Nota individual | Inteiro de 0 a 10 |
| Resultado | Média aritmética, uma casa decimal e total de votos |
| Encerramento | 10 segundos extras para votar |
| Mensagem | Até 140 caracteres, uma por voto |
| Campos de música | Título e artista obrigatórios, até 120 caracteres cada |
| Público de referência | Festa pequena, aproximadamente 5–30 pessoas |
| Projeção | Modos faixa inferior, lateral e intervalo |

## 5. Perfis e acesso

### Anfitrião

Cria e encerra a sala; opera a fila; confirma a disponibilidade da música no Singa; inicia, encerra ou aborta uma apresentação; modera mensagens; remove participantes abusivos e gerencia as configurações.

Proteger o acesso de anfitrião com credencial própria, separada do código público da sala. Para uma festa, uma sessão de host com segredo aleatório e mecanismo seguro de recuperação é suficiente; não criar um sistema amplo de contas sem necessidade. Nunca colocar o segredo no QR code ou no projetor.

O anfitrião também pode participar usando uma identidade de participante vinculada à sua sessão. Quando cantar, as mesmas restrições de voto se aplicam.

### Participante

Entra por código ou QR, escolhe apelido/emoji, pede músicas, cancela seus pedidos ainda pendentes, informa disponibilidade e vota nas apresentações de outras pessoas.

Apelidos devem ser únicos na sala ignorando maiúsculas e espaços nas pontas. Apelido não é autenticação: não permitir assumir uma identidade existente apenas digitando o mesmo nome.

Persistir a identidade com cookie seguro. Reabrir a página no mesmo navegador deve restaurar a participação. Outro dispositivo não assume automaticamente essa identidade; recuperação excepcional pode ser feita pelo anfitrião.

### Projetor

Página somente de leitura, sem controles administrativos. Exibe informações públicas da sala e resultados já revelados. Não recebe votos individuais ou dados administrativos, mesmo em campos ocultos, HTML ou eventos de WebSocket.

## 6. Jornada principal

1. O anfitrião cria uma sala e abre a página do projetor.
2. Convidados escaneiam o QR code e escolhem apelido/emoji.
3. Participantes enviam título e artista; o formulário avisa que o pedido depende de disponibilidade no karaokê.
4. A fila destaca quem canta agora e quem deve se preparar.
5. O anfitrião busca a música no Singa, confirma a versão e toca em “Começar apresentação”.
6. A votação abre nos celulares, exceto para os cantores.
7. Cada pessoa pode enviar e editar sua nota e mensagem até o prazo final.
8. Ao terminar a música, o anfitrião toca em “Encerrar música”.
9. O sistema abre os 10 segundos finais e informa a contagem regressiva.
10. O servidor fecha a votação e publica o resultado uma única vez.
11. O projetor mostra média, total de votos e cartões de mensagens.
12. O anfitrião avança para a próxima apresentação.

## 7. Fila justa: regra implementável

Evitar tanto repetições consecutivas quanto domínio da fila por quem envia muitos pedidos.

### Ordenação P0

1. Considere apenas pedidos pendentes de participantes disponíveis.
2. Considere somente o pedido mais antigo de cada pessoa para a próxima posição.
3. Se houver alternativa, exclua da próxima posição quem cantou na última apresentação concluída.
4. Entre os candidatos restantes, escolha quem tem menos apresentações concluídas na sala.
5. Desempate pela data/hora de criação do pedido e depois pelo ID, para ordem determinística.
6. Para prever as posições seguintes, simule a escolha, incremente a contagem do escolhido e repita com os pedidos restantes.

Uma pessoa que chegou depois começa com zero apresentações e tem prioridade pela regra acima. Esse comportamento é intencional na versão inicial. A posição mostrada é uma previsão e pode mudar com novas entradas ou disponibilidade.

Se só uma pessoa quiser cantar, permitir músicas consecutivas. Não deixar a festa parada por uma regra de alternância.

### Controles e exceções

- “Passar minha vez” marca a pessoa como indisponível e preserva seus pedidos; “Estou pronto” a recoloca na seleção.
- Pular alguém pelo painel produz o mesmo efeito, sem contar como apresentação.
- Pedido cancelado, indisponível no Singa ou apresentação abortada não incrementa a contagem.
- A apresentação em andamento nunca muda por recálculo da fila.
- O anfitrião pode definir explicitamente a próxima música, com indicação visual de ajuste manual. A exceção vale uma vez; depois volta a ordenação normal.
- Impedir novo pedido idêntico da mesma pessoa enquanto ainda estiver pendente. Pessoas diferentes podem pedir a mesma música.
- O limite de dois pedidos considera pedidos pendentes, não a apresentação em andamento.

Exemplo: Ana pede A1 e A2; Bruno pede B1; Carla pede C1. Todos com zero apresentações: A1 → B1 → C1 → A2. Se só Ana tiver pedidos, A1 → A2 é permitido.

### Extensão para duetos

Somente habilitar P1 quando as regras solo estiverem testadas. O parceiro precisa aceitar e ter vaga no limite de pedidos; pedidos em dupla contam para ambos. Ambos ficam impedidos de votar e recebem uma apresentação concluída em sua contagem.

Para ordenar, usar o maior número de apresentações concluídas entre os cantores. Evitar sobreposição com os cantores da apresentação anterior quando houver alternativa sem sobreposição. Um dueto é um único item da fila, elegível quando for o pedido mais antigo de todos os seus cantores; aceite atribui sua posição temporal na fila. Se alguém estiver indisponível, o dueto espera. Convite recusado nunca coloca alguém na fila.

## 8. Estados e concorrência

Separar o pedido de música da apresentação. Estados sugeridos:

| Entidade | Estados |
| --- | --- |
| Sala | open, closed |
| Pedido | queued, performing, completed, cancelled |
| Apresentação | performing, closing, revealed, aborted |

- Começar: cria apresentação e marca o pedido como performing em uma transação.
- Encerrar: performing → closing; grava voting_closes_at no servidor.
- Revelar: closing → revealed após o prazo, congela média/total e conclui o pedido.
- Abortar: performing/closing → aborted; descarta os votos do resultado público e cancela o pedido; host pode criar novo pedido depois.
- Só pode existir uma apresentação performing ou closing por sala.
- Cliques duplicados de iniciar/encerrar/revelar devem ser idempotentes.
- Serializar mutações relevantes com transação e lock na sala/apresentação; usar constraints e índices únicos no banco.
- Ao votar e ao fechar, usar a mesma disciplina de lock e revalidar o prazo dentro da transação.
- O relógio do servidor decide o prazo. O navegador apenas exibe a contagem.
- Encerrar a sala fica bloqueado enquanto houver apresentação ativa; o host deve concluí-la ou abortá-la primeiro. Pedidos remanescentes são cancelados ao fechar a sala.

## 9. Votos, resultados e anonimato

- Um voto por participante por apresentação, protegido por índice único.
- Valores fora de 0–10 ou não inteiros são rejeitados no servidor.
- O servidor identifica o votante pela sessão, nunca por um participant_id confiado ao formulário.
- Proibir votos de todos os cantores vinculados à apresentação.
- Congelar o conjunto de votantes elegíveis no início: participantes ativos da sala naquele momento, menos os cantores. Entradas posteriores participam da próxima apresentação. Remoção por moderação revoga o direito de votar; votos já aceitos permanecem para evitar alterações silenciosas da nota.
- A mensagem é opcional, mas precisa acompanhar uma nota; mensagem vazia é válida.
- O voto pode ser alterado enquanto performing ou enquanto closing antes do prazo.
- Nenhuma média parcial, distribuição de notas ou autoria de voto é enviada aos clientes.
- Revelar a média simples dos votos recebidos. Nota zero é válida; ausência de voto não é zero.
- Sem votos: exibir “Show entregue! Sem votos nesta rodada”, sem nota numérica.
- Média calculada com precisão decimal e arredondada apenas para exibição.
- Mensagens só aparecem publicamente depois da revelação, em ordem embaralhada fixada no resultado.
- A interface do anfitrião permite ocultar mensagens, sem expor o nome do autor. Ocultar mensagem não remove sua nota.
- Não prometer anonimato absoluto: mensagens são anônimas na experiência pública; o banco mantém a relação necessária para unicidade e moderação técnica.
- Escapar texto de usuário; não renderizar HTML enviado em nomes, títulos ou mensagens.

Frases rápidas iniciais: “Entregou tudo!”, “Quero bis!”, “Nasceu para o palco!” e “A plateia foi à loucura!”.

## 10. Interfaces

### Celular

Navegação curta: “Palco”, “Fila” e “Minhas músicas”. Mostrar o estado atual e uma ação principal por vez. Botões grandes, contraste alto, rótulos acessíveis e feedback claro de voto salvo. Exibir os números 0–10 como controles fáceis de tocar, sem depender apenas de slider.

Quando estiver cantando, mostrar “Sua vez de brilhar!” no lugar da votação. Avisa visualmente “Você é o próximo” sem depender de permissões de notificações.

### Anfitrião

Painel utilizável no celular e desktop: título/artista fáceis de copiar para busca manual, fila, disponibilidade, começar, encerrar, abortar, escolher próximo e moderação. Botões de transição desabilitados enquanto processam. Abortamento e fechamento da sala pedem confirmação na própria interface.

### Projetor

- Durante a música: cantor, música, próxima pessoa, QR code e “Votação aberta”.
- Intervalo: resultado em destaque, quantidade de votos e mensagens legíveis à distância.
- Fila: próximos três, com indicação de que a ordem pode mudar.
- Modos responsivos de faixa inferior e lateral, além de resultado ampliado.
- Tema escuro com acentos festivos; animações curtas, sem flashes e respeitando redução de movimento.
- Não colocar sons automáticos concorrendo com o Singa.

As janelas do Singa e do aplicativo serão organizadas manualmente no computador. Não assumir overlay sobre outra janela, incorporação por iframe, sincronização entre sites ou controle automático do projetor. Singa em tela cheia pode esconder a outra janela.

## 11. Arquitetura proposta

Aplicação Rails monolítica com PostgreSQL, views ERB, Turbo/Stimulus e Action Cable. Usar CSS simples ou o framework já presente. Não adicionar uma SPA ou microserviços sem necessidade concreta.

Para projeto novo, proposta inicial: PostgreSQL persistente e Redis para o transporte de Action Cable entre processos. Validar compatibilidade e custo no ambiente Railway antes de provisionar. Caso o repositório já use outro adapter de produção adequado, preservar e documentar a escolha. Não usar adapter apenas em memória como solução entre múltiplos processos.

O encerramento automático exige execução confiável no servidor: job persistente agendado para voting_closes_at e operação idempotente de finalização. Escolher o backend de jobs compatível com o Rails adotado e documentar seu worker. Acrescentar recuperação de apresentações com prazo vencido ao consultar o estado, para que reinício ou atraso do worker não deixe a festa travada.

### Modelo sugerido

| Modelo | Responsabilidade / campos principais |
| --- | --- |
| Room | Código, nome, status, configurações, credencial de host protegida |
| Participant | Sala, apelido, emoji, disponibilidade, revogação, identidade de sessão |
| SongRequest | Sala, solicitante, título, artista, status, dedicatória futura |
| SongRequestSinger | Pedido e participante; um cantor no P0, expansão para duetos |
| Performance | Sala, pedido, estado, início, prazo, revelação, média e total congelados |
| PerformanceSinger | Snapshot dos cantores no início |
| PerformanceVoter | Snapshot dos participantes elegíveis |
| Vote | Apresentação, participante, nota, mensagem, hidden_at |

Preferir contagem de apresentações derivada das apresentações reveladas; se houver cache, mantê-lo transacional. Relações e validações precisam impedir referências cruzadas entre salas. Não implementar tabelas de extras antes da fase correspondente.

### Serviços de domínio sugeridos

QueueOrder, StartPerformance, ClosePerformance, FinalizePerformance, AbortPerformance e CastVote. Nomes indicativos: adaptar às convenções do projeto, mantendo regras fora de controllers extensos.

### Tempo real

- Broadcast da fila após alterações relevantes e transições de apresentação.
- Streams públicos recebem apenas projeções públicas dos dados; stream de host separado e autorizado.
- Enviar resultado somente depois do commit da transação de revelação.
- Nunca transmitir votos individuais em stream compartilhado.
- Ao reconectar, buscar snapshot atual completo. Não depender de ter recebido todos os eventos.
- Identificar apresentação e revisão nos eventos para ignorar atualizações antigas.
- Mostrar conexão perdida e tentar recuperar; fallback por consulta periódica moderada se necessário.
- Não exibir sucesso em envio de voto sem confirmação do servidor. Repetição segura do envio atualiza o mesmo voto.

## 12. Segurança e confiabilidade essenciais

- Autorização no servidor para toda mutação e assinatura de canais.
- Isolamento de salas em consultas, formulários, endpoints e WebSockets.
- Proteções CSRF e cookies seguros em produção; validar origem dos WebSockets.
- Limites de tamanho de texto e frequência para entrada na sala, pedidos, votos e reações.
- QR code leva apenas à página pública de entrada.
- Credenciais e tokens fora do repositório e dos logs.
- Convidados não conseguem iniciar, encerrar ou moderar por chamada direta à API.
- Reinício do processo preserva participantes, fila, votos e apresentação em andamento.
- Remover participante deve revogar sua sessão, cancelar pedidos pendentes relacionados e impedir novas mutações.
- Não depender de armazenamento local efêmero para dados de negócio.

## 13. Comportamento dos extras

- Reações: aplausos, coração e fogo; no máximo uma reação por segundo por participante, agregadas em animações discretas; não alteram nota.
- Dedicatória: texto curto exibido no início, sujeito à mesma sanitização e moderação.
- Desafio: destinatário aceita ou recusa sem exposição constrangedora; só entra na fila após aceite e se houver vaga.
- Escolha da plateia: preservar o próximo cantor. Ele aprova 2–3 opções; cada participante tem um voto editável até o prazo. Empate ou ausência de votos deixa a escolha ao cantor/anfitrião. Resultado define uma música, sem gerar vários pedidos.
- Rodada temática: banner manual do host, inicialmente sem bloquear pedidos fora do tema.
- Prêmios: votação separada no final; categorias como melhor performance, dueto da noite e rei/rainha da sofrência. Não calcular silenciosamente a partir das notas.
- Ranking: opcional e desativado no início. Definir método e empates antes de implementar; não comparar totais acumulados que premiem apenas quem cantou mais.

## 14. Plano de execução

### Fase 0 — preparar

- [ ] Inspecionar repositório e ambiente.
- [ ] Registrar versões e decisões de infraestrutura.
- [ ] Preparar README, variáveis de exemplo sem segredos e ambiente local.

### Fase 1 — sala e identidade

- [ ] Criar sala e sessão protegida do anfitrião.
- [ ] Entrada por código/QR e identidade persistente.
- [ ] Separar interfaces e autorizações.

### Fase 2 — pedidos e fila

- [ ] Pedidos com validações e limite.
- [ ] Ordenação determinística e previsão da fila.
- [ ] Passar vez, retornar, cancelar e override de próximo.
- [ ] Atualizações em tempo real.

### Fase 3 — apresentação e resultado

- [ ] Máquina de estados e concorrência.
- [ ] Votos elegíveis, edição e mensagens.
- [ ] Prazo no servidor, job persistente e recuperação.
- [ ] Revelação, moderação e histórico mínimo da última apresentação.

### Fase 4 — operação da festa

- [ ] Layout mobile e modos de projetor.
- [ ] Recuperação após reconexão/reinício.
- [ ] Testes críticos e ensaio com dispositivos separados.
- [ ] Configuração Railway e runbook de deploy.
- [ ] Fechar P0 antes de implementar P1/P2.

## 15. Testes e critérios de aceite

Usar o framework de testes existente, ou Minitest em projeto novo. Priorizar regras de negócio e integração; evitar testes que só reproduzem markup.

- [ ] Ana A1/A2, Bruno B1, Carla C1 resulta em A1/B1/C1/A2.
- [ ] Último cantor não repete quando há outro elegível; repete quando está sozinho.
- [ ] Novato tem prioridade por contagem, com desempate estável.
- [ ] Passar vez preserva pedidos; voltar restaura elegibilidade.
- [ ] Dois cliques simultâneos de iniciar criam uma apresentação apenas.
- [ ] Só existe uma apresentação ativa por sala.
- [ ] Cantor não vota nem por requisição manipulada; estender a ambos no dueto.
- [ ] Voto repetido é atualização, sem duplicar contagem.
- [ ] Voto no limite do prazo e finalização concorrente produzem resultado consistente.
- [ ] Finalização repetida não duplica contagem ou resultado.
- [ ] Votos 0, 8 e 10 revelam 6,0 com três votos; nenhum voto não revela zero.
- [ ] Conteúdo de outra sala é inacessível.
- [ ] Projetor e participantes não recebem notas individuais nem resultados antecipados.
- [ ] Mensagem oculta some de todas as telas após atualização e não altera média.
- [ ] HTML em mensagens e apelidos é exibido como texto seguro.
- [ ] Reinício durante closing recupera a revelação com dados preservados.
- [ ] Reconexão recupera estado correto sem duplicar ações.
- [ ] Uma sessão de host, uma de projetor e três de participantes completam duas músicas no ensaio.
- [ ] Layout utilizável em Safari no iPhone e Chrome no Android, além do navegador do projetor; registrar o que foi efetivamente testado.

## 16. Comandos e execução local

O agente deve substituir exemplos por instruções verificadas no README. Não executar comandos de geração em um repositório existente sem inspeção.

Inspeção inicial sugerida:

```sh
pwd
git status --short
ruby --version
bundle --version
rg --files -g 'AGENTS.md' -g 'Gemfile*' -g '.ruby-version' -g 'README*' -g 'config/database.yml' -g 'config/cable.yml'
```

Somente para diretório novo e após instalar/selecionar as versões apropriadas:

```sh
rails new karaoke_party --database=postgresql
cd karaoke_party
```

Fluxo local esperado, após configurar banco e demais serviços:

```sh
bundle install
bin/rails db:prepare
bin/dev
```

Se bin/dev não existir, criá-lo ou documentar o comando equivalente. Documentar também como iniciar Redis e o worker escolhido. Não presumir que o processo web inicia esses serviços.

Verificação esperada, conforme configuração real do projeto:

```sh
bin/rails test
bin/rails test:system
```

Criar dados de demonstração somente em desenvolvimento/teste: uma sala e participantes fictícios. Nunca inserir dados de teste automaticamente em produção.

## 17. Railway: preparação e runbook

Validar a documentação oficial atual durante a implementação. Preparar:

1. Versões de Ruby e dependências fixadas, lockfile e build reproduzível.
2. Serviço web, PostgreSQL persistente, transporte de WebSocket e worker compatíveis com as decisões adotadas.
3. Variáveis de ambiente documentadas: RAILS_ENV, DATABASE_URL, SECRET_KEY_BASE ou RAILS_MASTER_KEY conforme configuração, URL pública da aplicação e REDIS_URL quando usado. Explicar quais são necessárias de fato.
4. Processo web escutando em 0.0.0.0 e na porta fornecida pela plataforma; comando depende da configuração final de Puma.
5. Compilação de assets e migrations em etapa controlada, sem rodar migrações concorrentes em cada worker.
6. Domínio HTTPS, cookies seguros, host permitido e origem autorizada para WebSockets.
7. Health check e logs úteis sem expor votos, mensagens ou segredos.
8. Verificação do worker, jobs agendados e comunicação de broadcasts entre processos.
9. Procedimento de reinício, backup e rollback compatível com as migrações feitas.
10. Teste real com celulares após deploy, incluindo reconexão e encerramento automático.

Não gravar comandos Railway especulativos como se tivessem sido executados. Se credenciais ou acesso faltarem, entregar configuração pronta e passos exatos restantes.

## 18. Roteiro do anfitrião para o ensaio

1. Abrir a sala, o Singa e a tela pública em janelas organizadas no projetor.
2. Conferir QR code e legibilidade das letras.
3. Entrar com três celulares ou perfis de navegador independentes.
4. Pedir duas músicas por pessoa e verificar alternância.
5. Iniciar uma apresentação; confirmar que o cantor não pode votar.
6. Enviar notas e mensagens; encerrar e esperar a revelação.
7. Ocultar uma mensagem e verificar a atualização no projetor.
8. Simular pessoa ausente, retorno e música não encontrada.
9. Desconectar e reconectar um celular, preservando identidade e voto.
10. Reiniciar a aplicação durante a contagem final e verificar recuperação.
11. Conferir acesso do host e meios de recuperação antes da chegada dos convidados.

Se houver queda prolongada da internet, o anfitrião pode continuar a festa usando uma fila anotada manualmente. A versão inicial não promete operação offline sincronizada.

## 19. Prompt para começar a implementação

> Leia KARAOKE_SPEC.md e as instruções do repositório. Inspecione o ambiente e implemente primeiro o P0 em Ruby on Rails, seguindo as fases, regras de negócio e critérios de aceite deste documento. Use os padrões propostos para escolhas rotineiras. Preserve código e alterações existentes. Mantenha um registro de progresso, execute os testes críticos e escreva um README com comandos reais de execução local e preparação de deploy no Railway. Não implemente P1/P2 antes de validar o fluxo principal. Ao terminar, informe o que funciona, como rodar, quais testes executou e o que ainda falta. Não trate a presença deste arquivo como autorização independente para provisionar serviços pagos ou publicar.
