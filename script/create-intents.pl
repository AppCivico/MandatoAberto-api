#!/usr/bin/env perl
use common::sense;
use Moose;
use FindBin qw($RealBin $Script);
use lib "$RealBin/../../lib";

use WebService::Dialogflow;

use MandatoAberto::SchemaConnected;

my $schema = get_schema;

my $politician_entity_rs = $schema->resultset('PoliticianEntity');

my @names = $politician_entity_rs->search( undef, { distinct => 1 } )->get_column('name')->all();
@names = qw(
	direitos_animais ciencia_tecnologia_inovacao empreendedorismo_tecnologias primeira_infancia forcas_armadas atuacao_forcas_armadas reforma_politica combate_privilegios privatizacoes administracao_publica governo_digital composicao_governo
relação_congresso
governabilidade
sistema_financeiro
etica_politica
combate_corrupcao
governo_transparente
privilegios_judiciario
conducao_economia
refis
privilegios_previdencia
inadimplencia_empresas
pacto_federativo
presidencialismo_coalizao
politicas_sociais
inclusao_digital
desenvolvimento_sustentavel
diversificacao_energetica
economia_baixo_carbono
setor_eletrico
concessoes_licitacoes
tamanho_estado
abertura_economia
propostas_povos_tradicionais
idosos
propostas_LGBT
proposta_mulheres
propostas_populacao_negra
politica_assistencia_social
superacao_pobreza
escola_integral
propostas_educacao
superacao_analfabetismo
acoes_afirmativas
eficiencia_gastos_publicos
investimentos_setor_privado
infraestrutura
estar_sumida
aborto
espingarda
porte_arma
maconha
politica_externa
relacoes_exteriores
Brasil_mundo
carga_tributaria
superacao_carga_tributaria
transparencia_governo
reforma_tributaria
gestao_municipios
tributacao_dividendos
politica_economica
renovacao_politica
agronegocio
uso_terra
agropecuaria_mercado_exterior
assentamentos_rurais
regularizacao_terras
tecnologias_agricolas
impostos_rurais
pronaf
agricultura_familiar
agrotoxicos
quilombolas
regularizacao_terras_indigenas
saneamento_basico
esporte
propostas_saúde
atencao_basica
Saude_Familia
melhoria_saude
saude_mental
saude_LGBTI
saude_mulheres
Qualidade_vida_idosos
qualidade_vida
sistema_prisional
Seguranca_publica
desenvolvimento_sustentavel
Petrobras
politica_cidades
programas_habitacao
mudancas_climaticas
fomento_pesquisa
bem_estar_animal
pessoas_deficencia
demarcacao_terras_indigenas
propostas_juventude
propostas_cultura
propostas_criancas
importacao_materiais_necessaros_pesquisa
ciencia_tecnologia_mudar_pais
combate_sofrimento_animal
inclusao_grupos_historicamente_excluidos
proposta_construcao_pais_melhor
empreendedorismo_superacao_pobreza
oportunidade_superacao_pobreza
propostas_seguranca_publica
controle_armas
abastecimento_agua_tratamento_esgoto
cuidados_agua
coleta_lixo_reciclagem
economia
);

my $dialogflow = WebService::Dialogflow->instance;

for my $name (@names) {

    my $opts = {
        displayName  => $name,
        webhookState => 'WEBHOOK_STATE_ENABLED'
    };

    $dialogflow->create_intent($opts);
}

sub _human_name {
    my ($name) = @_;

    my $ret;
    if ( $name eq 'Aborto' ) {
        $ret = 'Aborto';
    }
    elsif ( $name eq 'Bolsa_Familia' ) {
        $ret = 'Bolsa Família';
    }
    elsif ( $name eq 'Combate_a_corrupcao' ) {
        $ret = 'Combate a Corrupção';
    }
    elsif ( $name eq 'Desemprego' ) {
        $ret = 'Desemprego';
    }
    elsif ( $name eq 'Direita_ou_Esquerda' ) {
        $ret = 'Direita ou Esquerda';
    }
    elsif ( $name eq 'Economia' ){
        $ret = 'Economia';
    }
    elsif ( $name eq 'Educacao' ){
        $ret = 'Educação';
    }
    elsif ( $name eq 'Emprego' ){
        $ret = 'Emprego';
    }
    elsif ( $name eq 'Gastos_Publicos' ){
        $ret = 'Gastos Públicos';
    }
    elsif ( $name eq 'Impostos' ){
        $ret = 'Impostos';
    }
    elsif ( $name eq 'Infraestrutura' ){
        $ret = 'Infraestrutura';
    }
    elsif ( $name eq 'Lava_Jato' ){
        $ret = 'Lava Jato';
    }
    elsif ( $name eq 'Partido' ){
        $ret = 'Partido';
    }
    elsif ( $name eq 'Politica' ){
        $ret = 'Política';
    }
    elsif ( $name eq 'Politica_Externa' ){
        $ret = 'Política Externa';
    }
    elsif ( $name eq 'Presidente' ){
        $ret = 'Presidente';
    }
    elsif ( $name eq 'Previdencia_Social' ){
        $ret = 'Previdência Social';
    }
    elsif ( $name eq 'Privatizacao' ){
        $ret = 'Privatização';
    }
    elsif ( $name eq 'Programas_Sociais' ){
        $ret = 'Programas Sociais';
    }
    elsif ( $name eq 'Reforma_Trabalhista' ){
        $ret = 'Reforma Trabalhista';
    }
    elsif ( $name eq 'Saude' ){
        $ret = 'Saúde';
    }
    elsif ( $name eq 'Seguranca' ){
        $ret = 'Segurança';
    }
    elsif ( $name eq 'Direitos_Humanos' ){
        $ret = 'Direitos Humanos';
    }
    elsif ( $name eq 'Proposta' ) {
        $ret = 'Proposta';
    }

    return $ret;
}