# Registro de decisões

## DEC-001 — App nativo e núcleo independente

**Status:** adotada para desenvolvimento em 28 de outubro de 2026. Compatibilidade final depende do piloto.

O PRD exige notificações locais, áudio com tela bloqueada, autenticação do aparelho e armazenamento protegido. A interface usa SwiftUI e APIs nativas do iOS, com iOS 17 como mínimo inicial. Um pacote Swift sem dependências externas concentra as regras que podem ser testadas fora da interface. Uma aplicação web não atende integralmente a esses requisitos de integração com o iPhone.

O projeto é editável no Windows e compilável em macOS/Xcode. Um gerador Python determinístico mantém o projeto do Xcode versionado. Não há pacote de interface multiplataforma, backend de dados pessoais ou serviço pago de síntese de voz.

## DEC-002 — Persistência atômica e política de backup

**Status:** adotada para o MVP em desenvolvimento.

Um arquivo JSON com `schemaVersion = 1` contém o plano ativo, notas, ocorrências e preferências. As gravações usam substituição atômica e `completeFileProtection`. Formatos desconhecidos ou corrompidos são recusados sem substituir o arquivo original. A implementação inicial não tem um formato anterior a migrar; versões futuras precisam de migração testada antes de mudar o esquema.

O diretório e o arquivo são excluídos dos backups do sistema. A consequência é não prometer recuperação depois de desinstalação, troca ou perda do aparelho. Essa política aparece no primeiro uso e nos Ajustes. Não existe backup próprio do app no MVP.

## DEC-003 — Lembretes e capacidade

**Status:** adotada para desenvolvimento; comportamento final a verificar em iPhone.

Lembretes diários usam um único agendamento recorrente; dias selecionados usam agendamentos semanais identificáveis. O aplicativo mantém um orçamento conservador de 60 solicitações para práticas e uma para o temporizador. Exibe atividades omitidas e confere as solicitações pendentes devolvidas pelo sistema. Atualizações são serializadas, para impedir que uma gravação antiga recrie notificações removidas por uma edição recente.

Horários usam a hora local do aparelho. Mudanças significativas de hora, data e fuso provocam reconciliação. Avisos não incluem nome da atividade, perguntas ou notas. O iOS decide a apresentação conforme permissões, Foco e som.

## DEC-004 — Áudio local e pausas finitas

**Status:** implementada, com validação obrigatória em aparelho real.

O reprodutor compartilhado usa `AVSpeechSynthesizer` e as vozes instaladas no aparelho. As pausas do exame são intervalos finitos de áudio silencioso, reproduzidos por `AVAudioPlayer`, inclusive após a última pergunta. Pausar congela a posição desse intervalo. O Evangelho é uma única leitura contínua. Não há captura de microfone nem envio de perguntas para síntese externa.

`AVAudioSession` usa a categoria de reprodução com modo de fala e background audio. Interrupções e remoção de fone pausam a condução. A retomada de fala interrompida pode reiniciar a pergunta atual. Controles remotos usam o título neutro “Momento de reflexão”. A qualidade e disponibilidade de vozes masculinas e femininas não estão certificadas sem teste nos aparelhos suportados.

## DEC-005 — Fonte do Evangelho pendente

**Status:** decisão confirmada pelo responsável pelo produto em 28 de outubro de 2026.

Ainda não há fonte autorizada. Preparar o contrato de integração e registrar a pendência. O build inicial mantém a fonte desativada, sem scraping e sem passagens geradas. A liberação depende de confirmação dos direitos, revisão da edição e validação de datas litúrgicas, conforme [Evangelho](EVANGELHO.md).

## Referências de implementação

- [Notificações locais](https://developer.apple.com/documentation/usernotifications/scheduling-a-notification-locally-from-your-app)
- [Permissão de notificações](https://developer.apple.com/documentation/usernotifications/asking-permission-to-use-notifications)
- [Síntese de voz](https://developer.apple.com/documentation/avfoundation/speech-synthesis)
- [Sessão de áudio](https://developer.apple.com/documentation/avfaudio/avaudiosession)
- [Autenticação do aparelho](https://developer.apple.com/documentation/localauthentication/lapolicy/deviceownerauthentication)

Para cada decisão, usar o formato abaixo e preservar o histórico quando ela for substituída.

## Modelo

- **Identificador e título:** DEC-001 — título da decisão.
- **Data:** data da decisão.
- **Status:** proposta, aceita ou substituída.
- **Contexto:** problema e restrições.
- **Alternativas:** opções consideradas.
- **Decisão:** escolha adotada e motivo.
- **Consequências:** benefícios, limitações e trabalho necessário.
- **Referências:** issues e pull requests relacionados.
