# Validação do MVP

Este documento separa cobertura de código de evidência em execução. Um teste preparado não significa um requisito aprovado em iPhone.

## Ambiente

Desenvolvimento local em Windows. Projeto nativo SwiftUI com alvo iOS 17. Testes automatizados configurados no GitHub Actions em macOS, com pacote Swift e simulador de iPhone. Não houve teste em iPhone físico nem distribuição por TestFlight ou App Store nesta etapa.

## Cobertura por requisito

| Requisito | Implementação e teste automatizado | Verificação que continua necessária |
|---|---|---|
| RF01 | Momentos, reordenação, movimento de blocos, persistência e exclusão explícita | Uso do editor com VoiceOver e arraste em iPhone |
| RF02 | Atividades independentes, edição, ativação, movimento, comandos acessíveis | Arraste entre momentos e manutenção de aviso no sistema |
| RF03 | Repetição semanal, data local, conclusão idempotente e histórico | Virada de dia e fuso no aparelho |
| RF04 | Catálogo e criação de atividade livre; cópias independentes de roteiros | Avaliação do catálogo no piloto |
| RF05 | Planejamento de notificações, substituição e cancelamento, capacidade explícita | Alerta com app fechado, recusa/revogação, Foco, deep link e lista do sistema |
| RF06 | Contrato HTTP, data/calendário/edição, indisponibilidade, áudio do mesmo texto, cache condicionado | Fonte autorizada e correção litúrgica em datas comuns e especiais |
| RF07 | Três modelos editáveis, sessão silenciosa ou falada, nota opcional, roteiro vazio | Revisão editorial e fidelidade católica |
| RF08 | Vozes locais, amostra, pausas finitas, controles e interrupções | Medir 5/10 segundos, pausar silêncio, chamada, fone e tela bloqueada; validar vozes masculinas/femininas |
| RF09 | Timer por relógio, pausa/retomada, orações de abertura/fechamento | Dois minutos em background, alerta final e cancelamento no sistema |
| RF10 | Notas, exclusão confirmada, gravação atômica, autenticação e ocultação visual | Face ID/código, cancelamento de autenticação e prévia no alternador |

## Execução automatizada

O workflow `iOS MVP` executa:

1. Regeneração determinística do projeto e validação das propriedades do aplicativo.
2. `swift test` para modelos, persistência, calendário, timer, lembretes e contrato do Evangelho.
3. Compilação para simulador, sem assinatura de distribuição.
4. Testes de interface: exame sem respostas escritas, marcação de realização, anotação preservada após reinício, novo momento e prática livre.
5. Exportação de capturas e resultados do simulador para um artefato privado, com retenção de 14 dias.

O resultado de cada execução está no GitHub Actions. Os testes de interface usam dados isolados, disponíveis apenas no build de depuração. Nenhuma nota pessoal entra nas evidências.

### Evidência registrada em 28 de outubro de 2026

No commit `c7a4339`, a [execução em macOS](https://github.com/marcusalveseng-ops/app-devocional-plano-de-vida/actions/runs/40635015222) terminou com sucesso: geração do projeto, 28 testes do núcleo, compilação para simulador e 2 testes de interface. No iPhone 16 Pro simulado, foram verificados criação de momento e prática, exame sem respostas escritas, conclusão manual e anotação preservada após reinício. Os logs registram zero falhas nas duas suítes.

As capturas do primeiro uso, Hoje, Meu plano, Ajustes e reflexão foram inspecionadas. Os artefatos do workflow contêm as evidências. O teste de persistência compara o conteúdo efetivamente presente no editor com o exibido depois de salvar e reiniciar, evitando confundir alterações do teclado do simulador com perda de dados.

A validação local também conferiu os links relativos da documentação, as exclusões representativas do `.gitignore` e os arquivos versionados quanto a padrões comuns de credenciais, sem encontrar correspondências. Essa conferência não substitui a revisão de futuros arquivos antes de cada commit.

## Roteiro em aparelho real

1. Instalar com assinatura de desenvolvimento e criar um plano com duas atividades do mesmo tipo. Mover ambas, reiniciar o app e conferir textos, notas e lembretes.
2. Ativar um lembrete, recusando a permissão. Confirmar que o plano continua utilizável. Reativar a permissão nos Ajustes, mudar horário e dias e comparar solicitações pendentes. Excluir e desativar atividades e verificar cancelamento.
3. Testar lembrete com app fechado, Foco ativo e fuso alterado. Tocar no aviso com proteção habilitada, cancelar autenticação e conferir que o conteúdo não aparece. Autenticar e confirmar abertura da atividade correta, sem áudio automático.
4. Ouvir amostras das vozes em português. Executar um roteiro de três perguntas com 5 e 10 segundos de pausa. Cronometrar também a pausa final, pausar no meio do silêncio e retomar. Bloquear a tela, receber uma chamada e desconectar fones.
5. Iniciar leitura de dez minutos após a oração de abertura. Bloquear por dois minutos. Conferir tempo restante, pausa, retomada, aviso final, oração de fechamento e ausência de marcação automática.
6. Salvar, editar e excluir uma nota. Reiniciar e verificar cada resultado. Observar o alternador de apps, retorno protegido e comportamento com o código do aparelho indisponível.
7. Após resolver a fonte, executar a amostra de datas e falhas descrita em `EVANGELHO.md`.
8. Testar tamanhos maiores de texto, VoiceOver, contraste em modo escuro e os iPhones selecionados para o piloto.

## Critérios de lançamento

O piloto externo depende da revisão editorial e da validação dos fluxos acima. A liberação comercial também depende da fonte autorizada, definição de preço, identidade pública, conta de distribuição, revisão de privacidade e conformidade com o comportamento efetivamente verificado. Nenhuma destas pendências está implicitamente aprovada pela compilação.
