# PRD original

Transcrição do documento fornecido pelo responsável pelo produto. Versão 1.0, de 24 de outubro de 2026.

PRD do aplicativo
devocional católico

Produto mínimo viável para iPhone

Versão 1.0  |  24 de outubro de 2026  |  Responsável pelo produto Marcus Gabriel

O aplicativo permite organizar um plano de vida em blocos visuais e realizar as práticas com apoio de lembretes, textos e áudio. O MVP concentra o desenvolvimento no plano de vida, no Evangelho do dia e no exame de consciência guiado. Este documento orienta o desenho das telas, a estimativa técnica e a validação da primeira versão.

Objetivo e público

Ajudar o usuário a encaixar as práticas devocionais na rotina e acessá-las com poucos toques. O público inicial é formado por católicos de língua portuguesa, especialmente pessoas que seguem um plano de vida e frequentam meios de formação do Opus Dei. As atividades personalizadas permitem outros usos cristãos sem exigir recursos específicos de outras tradições no lançamento.

Decisões consolidadas

Tema | Definição para a primeira versão
Plataforma | Somente iPhone. Computador e Android ficam para versões posteriores.
Organização visual | Grupos por momentos do dia, com blocos ordenáveis e conexões sequenciais.
Lembretes | Notificações por horário e dias escolhidos. O nome do momento é editável.
Prioridades | Plano visual com lembretes, Evangelho diário e exames guiados por áudio.
Dados pessoais | Armazenamento local e bloqueio opcional. Sem sincronização entre aparelhos.
Conteúdo externo | Internet para obter o Evangelho. Leitura de livros feita fora do aplicativo.
Modelo comercial | Preferência por compra única na App Store. Preço ainda a definir.



Critério de escopo: Uma nova função entra no MVP se for necessária para montar o plano, lembrar uma prática ou realizá-la. O catálogo de atividades pode crescer usando as mesmas ferramentas básicas.

Os detalhes operacionais deste PRD são padrões propostos para implementação. Fornecedor do Evangelho, vozes definitivas, preço e versão mínima do iOS dependem de validação antes do lançamento.

Experiência e navegação

A tela Hoje apresenta o tronco do dia em uma coluna vertical adequada ao iPhone. Cada momento contém uma sequência de blocos. No modo de edição, o usuário reorganiza os momentos e as atividades. No uso diário, toca em um bloco para iniciar a prática.



Exemplo esquemático. Na tela do iPhone, os blocos se adaptam à largura e podem seguir na vertical.

Telas essenciais

Tela | Ação principal
Hoje | Consultar o plano do dia, abrir uma atividade e marcar sua realização.
Meu plano | Editar momentos, blocos, dias, horários e ferramentas. Inclui seleção do catálogo.
Atividade | Usar texto, temporizador, Evangelho ou exame conforme o tipo de bloco.
Ajustes | Escolher voz, pausas, proteção de acesso e consultar o estado das notificações.



Primeiro uso

Começar com um modelo editável ou um plano vazio. Adicionar as primeiras práticas, organizar os blocos e configurar os lembretes desejados. Pedir permissão de notificação quando o primeiro lembrete for ativado. A conta do aplicativo não é necessária para usar o plano local.

Princípios de uso

A ordem visual orienta a rotina e permite abrir qualquer prática. Um bloco não depende da conclusão de outro. O usuário controla o que marca como realizado. Usar linguagem serena e poucos controles por tela, respeitando o tamanho de texto do iOS e a navegação por VoiceOver. A conclusão registra a prática, sem atribuir pontuação à vida espiritual.

Requisitos do plano de vida

RF01 Plano e momentos do dia

Manter um plano ativo. Criar, renomear, reordenar e excluir momentos do dia. Oferecer grupos iniciais editáveis como Ao acordar, Durante o dia e Antes de dormir. Excluir um grupo com atividades exige mover seus blocos ou confirmar sua exclusão.

Aceitação: Após criar um momento, mover dois blocos e fechar o aplicativo, a mesma estrutura reaparece ao abrir. A exclusão de um momento nunca elimina atividades sem uma escolha explícita.

RF02 Blocos e conexões

Criar, editar, mover, desativar e excluir atividades. Cada bloco contém identificador, nome, tipo, momento, posição, dias da semana, duração opcional, lembrete opcional e configuração das ferramentas. As conexões refletem a ordem dos blocos e são atualizadas ao arrastar. Também oferecer comandos Mover para cima e Mover para baixo.

Aceitação: Mover um bloco entre momentos conserva suas perguntas, anotações e lembrete. A posição visual não altera automaticamente o horário da notificação. Todos os blocos continuam acessíveis fora da ordem planejada.

RF03 Repetição e realização diária

Permitir repetição diária ou em dias escolhidos da semana. Hoje exibe as atividades previstas para a data local do iPhone. O usuário pode marcar e desmarcar uma realização. A mudança de dia gera novas ocorrências sem apagar o plano nem as notas. Registros anteriores permanecem locais, sem um painel de estatísticas no MVP.

Aceitação: Uma prática configurada para domingo não aparece na segunda-feira. Concluir o bloco em um dia não o deixa concluído no seguinte. Duas marcações seguidas não duplicam o registro.

RF04 Catálogo inicial e atividade livre

Tipo de atividade | Ferramentas do MVP
Oração e devoção | Texto editável, modelo disponível, duração e lembrete opcionais. Abrange oferecimento de obras, terço, Ângelus e três Ave-Marias.
Oração mental | Temporizador, intenção ou propósito opcional e lembrete.
Leitura espiritual | Título do livro, duração e oração de abertura e encerramento. Conteúdo do livro permanece externo.
Evangelho e exame | Ferramentas específicas descritas em RF06 a RF08.
Prática livre | Nome, observações e lembrete. Abrange Missa, visita ao Santíssimo, visita a enfermos, caridade e confissão.



Aceitação: Criar uma visita a enfermos sem roteiro especializado. Criar dois blocos do mesmo tipo com configurações independentes, como oração mental de manhã e à tarde.

Notificações e Evangelho diário

RF05 Notificações vinculadas às atividades

Cada atividade pode ter um lembrete com hora e minuto, nos dias em que estiver prevista. Sugerir 12h para o Ângelus e 19h para o exame, sempre editáveis e sujeitos à ativação do usuário. Um momento chamado Ao sair do trabalho pode ter um bloco com notificação às 18h. O título do momento não detecta eventos da rotina.

Usar notificações locais do iOS [1, 2]. Ao editar horário ou dias, substituir o agendamento anterior. Ao desativar ou excluir a atividade, cancelar suas notificações futuras. Ao tocar no aviso, abrir a atividade correspondente, passando pelo bloqueio quando ativado. Não iniciar áudio automaticamente.

A apresentação do alerta segue as permissões, o modo Foco, o silêncio e as demais configurações do iPhone. Se a autorização for recusada ou revogada, manter o plano utilizável e mostrar como reativá-la. Exibir no aviso apenas uma mensagem discreta, como Hora da sua prática, sem notas ou perguntas pessoais.

Aceitação: Alterar um lembrete de 18h para 19h elimina o agendamento antigo. Excluir o bloco elimina seu aviso. Testar alerta com o app fechado, permissão recusada e abertura pelo aviso. O agendamento deve ser verificado no sistema, sem prometer alerta audível em qualquer configuração.

RF06 Evangelho do dia

Apresentar data, referência bíblica, texto e fonte. O recorte inicial é o calendário litúrgico romano usado no Brasil, com uma única edição textual autorizada. A fonte escolhida deve resolver domingos, festas e tempos litúrgicos. A data solicitada é a data local do aparelho, e não simplesmente a data UTC do servidor.

Disponibilizar leitura em tela e botão Ouvir, usando o mesmo reprodutor do exame. Buscar o texto pela internet. Uma cópia já obtida pode ser reutilizada conforme a permissão do fornecedor. Se o conteúdo da data não estiver disponível, exibir essa condição e oferecer nova tentativa. O conteúdo de outra data deve manter sua data visível e nunca aparecer como Evangelho de hoje.

Aceitação: Exibir o texto correto em um domingo e em uma data de festa fornecida pela fonte. Testar a virada do dia em Brasília, falha de rede, resposta vazia e retorno do serviço. Ler e ouvir o mesmo texto, sem gerar ou substituir passagens por IA.

Dependência de conteúdo

Antes da publicação, escolher uma fonte com cobertura e estabilidade adequadas e verificar os direitos de exibição, leitura em áudio e eventual armazenamento temporário. A existência de uma página ou API pública não será tomada como autorização comercial. Essa escolha permanece em aberto e deve ser resolvida no início do desenvolvimento.

Exame de consciência e áudio

RF07 Roteiros de exame

Oferecer três roteiros iniciais curtos: exame geral do dia, exame particular sobre um propósito e exame breve. Os textos editoriais serão escritos ou aprovados pelo responsável pelo produto e revisados quanto à fidelidade católica antes da distribuição. O usuário pode copiar um modelo para seu bloco, escrever perguntas, editar, reordenar e excluir itens.

Cada pergunta ocupa um item separado no editor. O exame mostra uma pergunta por vez e permite avançar ou retornar. Ao terminar, o usuário pode registrar uma nota ou propósito e marcar a atividade como realizada. Responder às perguntas é opcional; o usuário pode refletir em silêncio durante toda a sessão. Uma preparação pessoal para confissão pode usar o mesmo roteiro editável.

Aceitação: Editar um modelo em uma atividade não modifica o modelo original nem outro bloco. Uma sessão com três perguntas percorre as três na ordem escolhida. A ausência de resposta escrita não impede a conclusão. Um roteiro vazio recebe orientação para adicionar perguntas antes de iniciar.

RF08 Vozes e pausas

Converter o texto em fala por síntese de voz. O seletor apresenta uma amostra curta de cada opção. O objetivo de lançamento é oferecer ao menos uma voz masculina e uma feminina adequadas ao português do Brasil, condicionadas à validação de disponibilidade e qualidade nos iPhones suportados. A abordagem inicial usa vozes do sistema, processadas no aparelho [3].

Adotar uma pausa padrão de cinco segundos após cada pergunta, inclusive após a última, antes da tela de conclusão. Permitir escolher 0, 5, 10, 15 ou 30 segundos. A configuração vale para as perguntas do exame; o Evangelho usa leitura contínua. A voz escolhida é reaproveitada nas sessões seguintes.

O reprodutor permite iniciar, pausar, continuar, repetir a pergunta atual, avançar e encerrar. Pausar congela também a contagem do silêncio. Retomar continua do ponto pausado quando possível; após uma interrupção do sistema, oferecer retomada da pergunta interrompida. Uma chamada ou a desconexão do fone pausa a condução. Apenas um áudio do aplicativo toca por vez.

A condução deve continuar com a tela bloqueada. Os controles da tela bloqueada exibem um título neutro e oferecem pausa e retomada. Encerrar o processo não precisa preservar o ponto exato da reprodução, mas deve preservar o roteiro e as notas já salvas.

Aceitação: Trocar de voz e ouvir a amostra. Medir pausas de cinco e dez segundos. Pausar durante o silêncio, retomar, repetir uma pergunta e bloquear a tela. Verificar chamadas e fones em aparelho real. Uma voz indisponível deve gerar uma escolha de alternativa, sem falha silenciosa.

Ferramentas comuns e registros pessoais

RF09 Textos e temporizador

Textos de apoio podem ser selecionados entre modelos disponíveis e editados no bloco. O temporizador permite configurar a duração, iniciar, pausar, continuar e encerrar. Na leitura espiritual, oferecer dez minutos como sugestão e uma Ave-Maria de abertura e outra de encerramento. O usuário confirma o início da contagem depois da oração inicial.

O temporizador deve calcular o tempo por referência de relógio, de modo que bloquear a tela ou alternar de aplicativo não altere a duração. Seu término pode usar notificação local quando autorizada. Ele não marca automaticamente a prática como concluída. O timer não é oferecido no exame guiado nesta versão, evitando conflito com as pausas do áudio.

Aceitação: Iniciar dez minutos de leitura, bloquear a tela por dois minutos e retornar com o tempo correto. Pausar não consome tempo. Encerrar antes do prazo cancela o aviso de término. A oração final aparece ao encerrar a sessão de leitura.

RF10 Anotações e proteção de acesso

Permitir salvar, editar e excluir notas ligadas a uma prática ou sessão. Mostrar data e atividade para que o usuário possa reencontrá-las dentro do respectivo bloco. Separar as perguntas do roteiro das respostas ou reflexões pessoais. Gravar as alterações localmente de forma previsível e confirmar antes de apagar uma nota ou todos os registros de uma atividade.

Oferecer bloqueio opcional de acesso ao aplicativo. O padrão técnico proposto usa Face ID ou Touch ID, com o código do próprio iPhone como alternativa, conforme disponibilidade [4]. Se o aparelho não tiver código configurado, explicar a necessidade antes de ativar o bloqueio. Ao retornar ao app com a proteção habilitada, exigir nova autenticação; o áudio já iniciado pode continuar com controles neutros.

Proteger os arquivos pessoais com os mecanismos de armazenamento seguro do iOS e ocultar notas na prévia do alternador de aplicativos. Não enviar perguntas, respostas ou notas a serviços externos de voz, análise de uso ou registro de erros. O MVP não inclui gravação de respostas nem exige acesso ao microfone.

Aceitação: Uma nota salva reaparece após fechar e abrir o app. Excluí-la remove seu conteúdo da interface e da base ativa. Com o bloqueio habilitado, o aviso e a prévia do aplicativo não revelam notas; cancelar a autenticação mantém a tela protegida.

Dados e uso sem conexão

Plano, roteiros, preferências e notas ficam na base local. O app não terá sincronização nem backup próprio no MVP. Definir e documentar o tratamento dos backups do sistema antes do lançamento, sem prometer recuperação após troca, perda ou exclusão do aparelho. Falta de internet não impede editar o plano ou abrir textos locais; a busca de novo Evangelho depende da conexão. Vozes que exijam download devem informar essa condição.

Base técnica e operação do conteúdo

A arquitetura abaixo é uma recomendação para estimativa. O produto permanece limitado ao iPhone, com conteúdo público vindo de uma fonte externa e dados pessoais armazenados no aparelho.

Componente | Responsabilidade
Interface nativa | Construir as telas de Hoje, edição do plano, atividade e ajustes. SwiftUI é a opção inicial a avaliar.
Persistência local | Guardar plano, ocorrências diárias, roteiros, notas e preferências. A tecnologia deve suportar evolução do formato sem perda de dados.
Notificações do iOS | Agendar e cancelar lembretes, verificar autorização e abrir a atividade correta [1, 2].
Áudio compartilhado | Uma implementação para ler o Evangelho e as perguntas, com controle explícito de pausas [3].
Proteção de acesso | Autenticação nativa e armazenamento protegido. Código do aparelho como alternativa à biometria [4].
Fonte do Evangelho | Obter conteúdo por data, validar resposta e tratar indisponibilidade. Um serviço intermediário só entra se necessário para a fonte ou para proteger credenciais.



Estrutura mínima dos dados

Plano contém Momentos; cada Momento contém Atividades ordenadas. Atividade guarda tipo, configuração e repetição. Ocorrência identifica atividade e data local, com estado de realização. Roteiro contém perguntas ordenadas. Nota pertence à atividade e, quando aplicável, à ocorrência. Preferências guardam voz, pausa e bloqueio. Conteúdo diário identifica data, calendário, edição, referência e origem.

O identificador da atividade deve permanecer estável após renomear ou mover o bloco. Excluir um bloco deve tratar explicitamente as notas associadas. Editar a repetição modifica as próximas ocorrências; não reescreve os registros passados. Alterações de fuso e de relógio exigem reavaliação do plano e dos agendamentos para evitar duplicações.

Conteúdo editorial e manutenção

Manter os modelos de oração e exame em um pacote pequeno e versionado. Registrar autoria, origem e condições de uso dos textos distribuídos. Não incorporar livros da Quadrante ou de outros autores; guardar somente o título informado pelo usuário e os controles de apoio à leitura. Para Evangelho, validar também datas especiais e correções de conteúdo.

Compra única

Estimar os custos de distribuição, licenças de conteúdo, serviço do Evangelho e manutenção antes de definir o preço. A proposta inicial evita geração de voz paga a cada uso. O preço, a disponibilidade territorial e as condições de futuras atualizações comerciais serão definidos antes da publicação, sem incluir cobrança recorrente neste MVP.

Entrega e validação do MVP

Ordem de implementação

Etapa | Entrega verificável
1 Viabilidade | Testar as vozes em português em iPhone real; definir fonte do Evangelho, permissões e versão mínima do iOS. Validar áudio com tela bloqueada.
2 Plano e lembretes | Implementar modelo inicial, editor de grupos e blocos, repetição, Hoje, persistência e notificações.
3 Práticas guiadas | Implementar roteiros editáveis, reprodutor compartilhado, pausas, Evangelho e temporizador.
4 Proteção e revisão | Concluir notas, bloqueio, tratamento de falhas, acessibilidade, revisão editorial e testes em aparelhos reais.
5 Piloto e publicação | Realizar o piloto, corrigir impedimentos de uso, fechar preço e conteúdo e preparar a distribuição na App Store.



Condições para liberar a primeira versão

RF01 a RF10 verificados com evidência de execução. Criar um plano, fechar o app e reencontrar a mesma configuração sem perda de dados.

Notificações testadas com app fechado, permissão recusada, edição de horário, exclusão do bloco e mudança de data ou fuso. Se o sistema limitar agendamentos, informar quais não foram ativados.

Evangelho validado com uma amostra de datas comuns e especiais. Falha de rede ou da fonte não apresenta leitura de outra data como atual.

Áudio testado em aparelho real com vozes masculinas e femininas em português, pausas, tela bloqueada, interrupção por chamada e desconexão de fone.

Notas e roteiros preservados após reinício. Proteção testada no aviso, na prévia de aplicativos e no retorno à interface. Nenhum texto pessoal aparece nos registros técnicos.

Fonte e autorização dos conteúdos documentadas, modelos revisados, preço definido e descrição comercial coerente com o que está implementado.

Piloto proposto

Testar por 14 dias com Marcus e um grupo pequeno de cinco a oito usuários. As metas abaixo são hipóteses de validação do produto, não resultados já medidos. Usar observação e feedback voluntário, sem coletar o conteúdo dos exames.

Meta | Como verificar
Configuração compreensível | Pelo menos 80% montam três atividades e um lembrete em até cinco minutos, sem ajuda.
Áudio utilizável | Pelo menos 80% escolhem uma voz, mudam a pausa e concluem um exame sem ajuda.
Valor na rotina | Marcus usa o app em pelo menos dez dos 14 dias e consegue manter nele as práticas principais.
Confiabilidade | Nenhuma falha crítica de perda de notas, exposição de dados ou travamento que impeça as três funções centrais.



Limites e decisões para lançamento

Recursos para versões posteriores

Computador, Android, sincronização, Bíblia completa e planos de leitura por capítulos, Missal completo, Liturgia das Horas, gravações históricas ou vozes que reproduzam pessoas reais, relatórios avançados, sequências de dias, recorrências mensais e anuais, importação e exportação do plano. O editor com posicionamento totalmente livre e ramificações também permanece fora do MVP.

Essas expansões devem ser priorizadas após o piloto. A leitura de livros continua externa por decisão de produto; o aplicativo acompanha a prática com texto de apoio e temporizador.

Decisões ainda necessárias

Decisão | Momento de resolução
Fonte e edição do Evangelho | No início da implementação. Confirmar cobertura do calendário, direitos de exibição e áudio, custo e disponibilidade.
Vozes finais | Na prova técnica. Validar ao menos uma opção masculina e uma feminina em português nos aparelhos suportados.
Textos de oração e exame | Antes do piloto externo. Aprovar redação, origem e condições de distribuição.
Versão mínima do iOS e backups | Antes de fechar a implementação. Testar compatibilidade, armazenamento e recuperação conforme a política escolhida.
Nome público e preço | Antes da publicação. Escolher identidade própria e calcular a viabilidade da compra única.



Referências técnicas

Documentação oficial da Apple consultada em 24 de outubro de 2026. As referências sustentam as opções técnicas; disponibilidade e comportamento devem ser confirmados nos aparelhos e versões de iOS selecionados.

[1] Scheduling a notification locally from your app

[2] Asking permission to use notifications

[3] Speech synthesis

[4] LAPolicy deviceOwnerAuthentication

Uso deste documento

Este PRD define o produto a construir e os critérios para verificar sua primeira versão. O próximo trabalho é desenhar as telas essenciais e validar a fonte do Evangelho e as vozes, antes de estimar prazo e esforço de desenvolvimento. Novas funções devem ser avaliadas contra o recorte estabelecido, mantendo as três prioridades do MVP.
