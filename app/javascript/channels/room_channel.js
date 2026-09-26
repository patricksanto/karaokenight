import consumer from "channels/consumer"

const roomCode = document.querySelector("[data-room-code]")?.dataset.roomCode;

if (roomCode) {
  consumer.subscriptions.create({ channel: "RoomChannel", room_code: roomCode }, {
    connected() {
      console.log("[RoomChannel] connected to room:", roomCode);
    },

    disconnected() {
      console.log("[RoomChannel] disconnected");
    },

    received(data) {
      console.log("[RoomChannel] received:", data.type);

      const isProjector = !!document.querySelector(".proj-wrap, .proj[data-room-code]");

      switch (data.type) {
        // Fila de músicas atualizada
        case "queue_changed": {
          const el = document.querySelector("#queue-content");
          if (el) el.outerHTML = data.html;
          break;
        }

        // Performance iniciou, fechou, finalizou ou abortou — substitui o conteúdo da stage
        case "performance_started":
        case "stage_update": {
          // No projector: recarrega a página inteira para refletir novo estado
          if (isProjector) {
            setTimeout(() => location.reload(), 350);
            break;
          }
          // Na stage mobile: substitui o innerHTML do #stage-content
          const stageMain = document.getElementById("stage-content");
          if (stageMain && data.html) {
            stageMain.innerHTML = data.html;
            // Re-executa scripts injetados no partial
            stageMain.querySelectorAll("script").forEach(oldScript => {
              const newScript = document.createElement("script");
              newScript.textContent = oldScript.textContent;
              oldScript.replaceWith(newScript);
            });
          }
          break;
        }

        // Contador de votos atualizado em tempo real
        case "vote_update": {
          // Stage mobile: atualiza o social proof
          const counter = document.querySelector(".sg-sp-text");
          if (counter && data.votes_count !== undefined) {
            counter.textContent = `${data.votes_count} room members rated`;
          }

          // Projector: atualiza live score + mensagem flutuante
          if (isProjector) {
            if (typeof updateLiveScore === "function") {
              updateLiveScore(data.average_score, data.votes_count);
            }
            if (data.message && typeof showFloatingMessage === "function") {
              showFloatingMessage(data.message);
            }
          }
          break;
        }

        // Reactions atualizadas em tempo real
        case "reaction_update": {
          const counts   = data.counts   || {};
          const total    = data.total    ?? 0;
          const lastKind = data.last_kind;

          // Stage mobile: atualiza contadores + float local (de outros participantes)
          Object.entries(counts).forEach(([kind, count]) => {
            const el = document.getElementById(`sg-rc-${kind}`);
            if (el) el.textContent = count;
          });
          const totalEl = document.getElementById("sg-reactions-total");
          if (totalEl) totalEl.textContent = `${total} sent`;

          // Float na stage: NÃO — cada um vê só o próprio (já acontece no click em sendReaction)

          // Projector: atualiza counts + float para todo mundo ver
          if (isProjector) {
            Object.entries(counts).forEach(([kind, count]) => {
              const el   = document.getElementById(`rc-${kind}`);
              const item = document.getElementById(`ri-${kind}`);
              if (el) {
                el.textContent = count;
                if (count > 0) item?.classList.add("active");
              }
            });
            // Float na coluna do cantor
            if (lastKind && typeof floatEmoji === "function") {
              floatEmoji(lastKind, "proj-emoji-float-zone");
            }
            // Hype background progressivo (10 / 30 / 50 reactions)
            if (typeof updateHypeLevel === "function") {
              updateHypeLevel(total);
            }
          }
          break;
        }
      }
    }
  });
}
