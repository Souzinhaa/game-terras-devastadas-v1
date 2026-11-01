> Registro de referência React/edições anteriores. Valores, status e pendências descrevem a etapa deste documento. Para o Android atual, consulte [contexto](../context.md), [regras Godot 0.7](../rules.md) e [Como jogar](COMO_JOGAR.md). Não presumir paridade entre motores.

# Limpeza de arquivos v0.5

Foram removidos os pacotes de importação duplicados em assets/cartas, assets/hostis, assets/marcadores e assets/consumiveis. A aplicação consulta as imagens canônicas em public/assets e os registros em src/data. As seis imagens de recursos agora têm cópia canônica pública e componente dedicado. Nenhum mapa, carro, hostil ou carta em uso foi excluído.

Os documentos de regras antigos GDD v0.4, DOCX v0.1, ATUALIZACAO_V04 e IMPLEMENTACAO foram substituídos por rules.md, rules-cards.md e context.md. O histórico completo continua no Git. Os documentos atuais de integração/UI foram mantidos e suas referências atualizadas.

Não se deve reimportar os contextos antigos dos ZIPs: eles reativariam setup, frequências e valores superados. Este arquivo registra a intenção da limpeza; testes e build confirmam as referências utilizadas.
