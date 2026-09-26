# Karaoke Party — Plano de Tarefas para Sábado

Status: plano de execução para festa de sábado.
Stack: Rails 8.1.3.1, Ruby 3.3.6, SQLite, Turbo/Stimulus, Action Cable (solid_cable), solid_queue.
Telas: (1) Telão landscape — sempre no projetor; (2) Mobile — menu fixo STAGE / QUEUE / MY SONGS.

---

## Ordem de execução

Cada fase deve funcionar antes de avançar. Commits pequenos e verificáveis.

---

### FASE 0 — Base e setup (~30 min) ✅

- [x] 0.1 — `bundle install` sem erro
- [x] 0.2 — Adicionar gems: `bcrypt`, `rqrcode` → `bundle install`
- [x] 0.3 — `bin/rails db:prepare` sem erro
- [x] 0.4 — Confirmar `bin/dev` sobe o servidor
- [x] 0.5 — Criar layout base com viewport mobile, meta tags e PWA basics

---

### FASE 1 — Modelos e migrations (~1h) ✅

- [x] 1.1 — Migration e model `Room` (code, name, status, host_token_digest, settings)
- [x] 1.2 — Migration e model `Participant` (room_id, nickname, emoji, session_token_digest, available, revoked_at)
- [x] 1.3 — Migration e model `SongRequest` (room_id, participant_id, title, artist, status)
- [x] 1.4 — Migration e model `SongRequestSinger` (song_request_id, participant_id)
- [x] 1.5 — Migration e model `Performance` (room_id, song_request_id, status, started_at, voting_closes_at, revealed_at, average_score, votes_count, messages_order)
- [x] 1.6 — Migration e model `PerformanceSinger` (performance_id, participant_id)
- [x] 1.7 — Migration e model `PerformanceVoter` (performance_id, participant_id)
- [x] 1.8 — Migration e model `Vote` (performance_id, participant_id, score, message, hidden_at)
- [x] 1.9 — Validações, associações, índices únicos e constraints em todos os models
- [x] 1.10 — Seeds de desenvolvimento (sala + participantes fictícios)

---

### FASE 2 — Login e identidade (~1h) ✅

- [x] 2.1 — Tela de login mobile-first: campo nome + seleção de emoji
- [x] 2.2 — Controller de sessão: cria participant com session_token_digest
- [x] 2.3 — Cookie persistente (expires 30 dias) para manter login a noite toda
- [x] 2.4 — Restaurar identidade ao reabrir navegador pelo cookie
- [x] 2.5 — Validação: apelido único por sala (case-insensitive, trim), 2–24 chars
- [x] 2.6 — Emoji obrigatório com lista de opções (padrão se não escolher)

---

### FASE 3 — Criação e entrada em sala (~1h) ✅

- [x] 3.1 — Página inicial: criar sala (anfitrião) OU entrar por código
- [x] 3.2 — Geração de código curto (6 chars, sem ambíguos) único entre salas abertas
- [x] 3.3 — Geração de host_token seguro (nunca exposto no QR/projetor)
- [x] 3.4 — Entrada por código: redireciona para login se não tiver sessão
- [x] 3.5 — QR code na página da sala (aponta para URL pública de entrada)
- [x] 3.6 — Rotas e autorização: separar participante / anfitrião / projetor

---

### FASE 4 — Pedidos de música (~1h) ✅

- [x] 4.1 — Formulário de pedido: título + artista (obrigatórios, máx 120 chars cada)
- [x] 4.2 — Limite de 2 pedidos pendentes por participante
- [x] 4.3 — Impedir pedido idêntico pendente da mesma pessoa
- [x] 4.4 — Cancelar pedido próprio pendente
- [x] 4.5 — Marcar disponível / indisponível (passar vez / voltar)

---

### FASE 5 — Fila justa (~1h30) ✅

- [x] 5.1 — Service `QueueOrder`: ordenação determinística conforme spec
- [x] 5.2 — Regra: pedido mais antigo por pessoa → menos apresentações → desempate por data/ID
- [x] 5.3 — Último cantor não repete quando há alternativa; repete quando está sozinho
- [x] 5.4 — Passar vez preserva pedidos, remove da elegibilidade
- [x] 5.5 — Apresentação abortada não conta; pedido cancelado não entra na fila
- [x] 5.6 — Exibir fila prevista para participante, host e projetor
- [x] 5.7 — Override manual do próximo pelo anfitrião

---

### FASE 6 — Apresentação e votação (~2h) ✅

- [x] 6.1 — Service `StartPerformance`: transação, impede 2 apresentações ativas
- [x] 6.2 — Service `ClosePerformance`: performing → closing, define voting_closes_at
- [x] 6.3 — Job persistente (solid_queue) para finalização automática após prazo (10s)
- [x] 6.4 — Recuperação de apresentações com prazo vencido ao consultar estado
- [x] 6.5 — Service `CastVote`: 0–10 inteiro, mensagem opcional 140 chars, edição até prazo
- [x] 6.6 — Bloquear voto do cantor (server-side)
- [x] 6.7 — Snapshot de votantes elegíveis no início da apresentação
- [x] 6.8 — Service `FinalizePerformance`: congela média (1 casa decimal), total, ordem de mensagens
- [x] 6.9 — Service `AbortPerformance`: aborta, cancela pedido, não conta apresentação
- [x] 6.10 — Idempotência em todas as transições

---

### FASE 7 — Tela Mobile (mobile-first) (~2h) ✅

- [x] 7.1 — Layout mobile: menu fixo inferior com 3 ícones (STAGE, QUEUE, MY SONGS)
- [x] 7.2 — **STAGE**: apresentação atual, cantor, música, botão de voto (0–10) ou "Sua vez!" se cantando, "Você é o próximo" se aplicável
- [x] 7.3 — **QUEUE**: fila prevista com próximos cantores, indicador de posição do usuário
- [x] 7.4 — **MY SONGS**: pedidos próprios pendentes, botão cancelar, formulário novo pedido
- [x] 7.5 — Controles de voto: botões 0–10 grandes (não só slider), mensagem opcional, frases prontas
- [x] 7.6 — Feedback visual: voto salvo, carregamento, erro, conexão perdida
- [x] 7.7 — Tema escuro, botões grandes, contraste alto, touch-friendly

---

### FASE 8 — Tela Telão / Projetor (landscape) (~2h) ✅

- [x] 8.1 — Layout landscape otimizado para projetor, tema escuro com acentos festivos
- [x] 8.2 — Durante música: cantor, música, próxima pessoa, QR code, "Votação aberta"
- [x] 8.3 — Intervalo: resultado em destaque, quantidade de votos, mensagens anônimas (legíveis à distância)
- [x] 8.4 — Fila: próximos 3 com indicação de ordem pode mudar
- [x] 8.5 — Animações curtas, sem flashes, respeitando prefers-reduced-motion
- [x] 8.6 — Sem áudio automático (não compete com Singa)
- [x] 8.7 — Modos: faixa inferior, lateral, resultado ampliado

---

### FASE 9 — Painel do Anfitrião (~1h30) ✅

- [x] 9.1 — Dashboard: código da sala, QR, link projetor, link público
- [x] 9.2 — Fila com controles: iniciar apresentação, encerrar, abortar, escolher próximo
- [x] 9.3 — Lista de participantes com disponibilidade e ações (remover, toggle disponível)
- [x] 9.4 — Mensagens reveladas com ação de ocultar
- [x] 9.5 — Título/artista fáceis de copiar para busca no Singa
- [x] 9.6 — Confirmação para abortar e fechar sala
- [x] 9.7 — Botões desabilitados enquanto processam (idempotência visual)

---

### FASE 10 — Tempo real (Action Cable + Turbo Streams) (~1h30) ✅

- [x] 10.1 — Broadcast da fila após alterações
- [x] 10.2 — Broadcast de transições de apresentação (start, close, reveal, abort)
- [x] 10.3 — Broadcast de resultado somente após commit da transação
- [x] 10.4 — Streams separados: público (projetor), participante, host
- [x] 10.5 — Nunca enviar notas individuais ou dados privados em stream compartilhado
- [x] 10.6 — Reconexão: buscar snapshot completo, não depender de eventos perdidos
- [x] 10.7 — Indicador "conexão perdida" + retry automático
- [x] 10.8 — Identificação de revisão nos eventos para ignorar updates antigos

---

### FASE 11 — Segurança (~30 min) ✅

- [x] 11.1 — Autorização server-side em toda mutação
- [x] 11.2 — Isolamento de sala em todas as queries
- [x] 11.3 — CSRF protection + cookies seguros
- [x] 11.4 — Escapar HTML em nomes, músicas e mensagens
- [x] 11.5 — Limites de tamanho e frequência (rate limiting básico)
- [x] 11.6 — Projetor não recebe dados privados (nem em HTML oculto)
- [x] 11.7 — Convidados não conseguem actions de host por API direta

---

### FASE 12 — Testes críticos (~1h) ✅

- [x] 12.1 — Fila: Ana A1/A2, Bruno B1, Carla C1 → A1, B1, C1, A2
- [x] 12.2 — Último cantor não repete com alternativa; repete sozinho
- [x] 12.3 — Dois cliques simultâneos de iniciar criam uma apresentação
- [x] 12.4 — Cantor não vota nem por requisição manipulada
- [x] 12.5 — Voto repetido atualiza sem duplicar
- [x] 12.6 — Finalização idempotente
- [x] 12.7 — Isolamento entre salas
- [x] 12.8 — HTML escapado em inputs de usuário
- [x] 12.9 — Reinício durante closing recupera revelação

---

### FASE 13 — Polimento e ensaio (~1h) ✅

- [x] 13.1 — Testar com 3 celulares na mesma rede local
- [x] 13.2 — QR code aponta para IP local (não localhost)
- [x] 13.3 — Refresh em todas as telas recupera estado
- [x] 13.4 — Identidade persistente após fechar/abrir navegador
- [x] 13.5 — Ensaio completo: 2 músicas com host + projetor + 3 participantes
- [x] 13.6 — Simular queda de conexão e reconexão

---

## Resumo de dependências

```
FASE 0 → FASE 1 → FASE 2 → FASE 3 → FASE 4 → FASE 5 → FASE 6
                                                        ↓
                                              FASE 7 (mobile)
                                              FASE 8 (telão)
                                              FASE 9 (host)
                                                        ↓
                                              FASE 10 (tempo real)
                                              FASE 11 (segurança)
                                              FASE 12 (testes)
                                              FASE 13 (ensaio)
```

## Estimativa total: ~14h de trabalho focado

## Gems a adicionar

- `bcrypt` — has_secure_password para host_token_digest e session_token_digest
- `rqrcode` — gerar QR codes

## Decisões de produto (conforme spec)

| Item | Valor |
|---|---|
| Apelido | 2–24 chars |
| Pedido máx | 2 por pessoa |
| Nota | 0–10 inteiro |
| Mensagem | até 140 chars, opcional |
| Prazo votação | 10 segundos |
| Código sala | 6 chars |
| Sessão | cookie 30 dias |
| Público | 5–30 pessoas |
