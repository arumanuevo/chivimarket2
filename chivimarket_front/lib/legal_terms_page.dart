import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'main.dart'; // Para GlassContainer y tema

class LegalTermsPage extends StatefulWidget {
  const LegalTermsPage({Key? key}) : super(key: key);

  @override
  State<LegalTermsPage> createState() => _LegalTermsPageState();
}

class _LegalTermsPageState extends State<LegalTermsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Términos y Avisos Legales',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: primaryColor,
          labelColor: primaryColor,
          unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          tabs: const [
            Tab(icon: Icon(Icons.gavel, size: 20), text: 'Términos Generales'),
            Tab(icon: Icon(Icons.swap_horiz, size: 20), text: 'Mercadería y Trueque'),
            Tab(icon: Icon(Icons.card_membership, size: 20), text: 'Suscripciones'),
            Tab(icon: Icon(Icons.security, size: 20), text: 'Privacidad y Datos'),
          ],
        ),
      ),
      body: AnimatedGradientBackground(
        child: SafeArea(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildGeneralTermsTab(isDark, primaryColor),
              _buildBarterAndTradeTab(isDark, primaryColor),
              _buildSubscriptionsTab(isDark, primaryColor),
              _buildPrivacyTab(isDark, primaryColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryBox(String title, String summary, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  summary,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.35,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.85),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSectionItem(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            content,
            textAlign: TextAlign.justify,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.5,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralTermsTab(bool isDark, Color primaryColor) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSummaryBox(
          'En pocas palabras (Aviso Fundamental)',
          'ChiviMarket es una plataforma digital comunitaria de contacto e información entre vecinos y comercios de Chivilcoy. No cobramos comisiones por compras directas ni somos propietarios, distribuidores o garantes de los productos y servicios ofrecidos por terceros.',
          Icons.info_outline,
          Colors.orangeAccent,
        ),
        GlassContainer(
          borderRadius: 20,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionItem(
                '1. Naturaleza del Servicio e Intermediación Tecnológica',
                'ChiviMarket pone a disposición una plataforma web y móvil que funciona como vidriera y catálogo digital local para facilitar el encuentro entre vendedores, prestadores de servicios y potenciales compradores en la ciudad de Chivilcoy y zonas de influencia. ChiviMarket no es parte en las relaciones jurídicas, transacciones comerciales ni acuerdos que los usuarios celebren entre sí.',
              ),
              _buildSectionItem(
                '2. Deslinde de Responsabilidad sobre Bienes y Operaciones',
                'Al igual que los estándares reconocidos para plataformas de intermediación de la sociedad de la información, ChiviMarket no tiene la posesión material, custodia, ni realiza el control de calidad previo de los artículos publicados. Cada comerciante o usuario vendedor es el exclusivo responsable por la existencia, licitud, estado de conservación, garantía, facturación y precio de sus productos.',
              ),
              _buildSectionItem(
                '3. Promociones, Vouchers y Cupones',
                'Los cupones de descuento, vouchers y beneficios publicados por comercios adheridos están sujetos a los términos, plazos y disponibilidad establecidos por cada negocio emisor. ChiviMarket no responderá ante negativas o discrepancias atribuibles al comercio.',
              ),
              _buildSectionItem(
                '4. Prohibición de Contenido Ilícito',
                'Queda terminantemente prohibido publicar o coordinar el intercambio de armas de fuego, medicamentos o estupefacientes, sustancias peligrosas, bienes robados, réplicas no autorizadas, material con derechos de autor sin licencia o cualquier bien contrario a las leyes argentinas vigentes. ChiviMarket se reserva el derecho de suspender o expulsar a infractores sin previo aviso.',
              ),
              _buildSectionItem(
                '5. Ley Aplicable y Jurisdicción',
                'Los presentes Términos se rigen por la legislación de la República Argentina. Toda controversia derivada de la utilización de la plataforma será sometida a los Tribunales Ordinarios de la Provincia de Buenos Aires (Departamento Judicial Mercedes), con renuncia a cualquier otro fuero que pudiera corresponder.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildBarterAndTradeTab(bool isDark, Color primaryColor) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSummaryBox(
          'Intercambios, Trueque y Artículos Usados',
          'Los acuerdos de trueque y compraventa de artículos usados se celebran estrictamente bajo la exclusiva responsabilidad y voluntad de las partes involucradas. Verificá siempre el estado y origen de los bienes antes de concretar.',
          Icons.swap_horiz,
          Colors.blueAccent,
        ),
        GlassContainer(
          borderRadius: 20,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionItem(
                '1. Mecanismo de Trueque e Intercambio Comunitario',
                'ChiviMarket promueve la economía circular y la colaboración comunitaria a través de herramientas de contacto para el intercambio de bienes muebles usados o nuevos. La plataforma no tasa, ni perita, ni interviene en la equivalencia de valor acordada entre las partes.',
              ),
              _buildSectionItem(
                '2. Declaración de Legitimidad de los Bienes',
                'Todo usuario que ofrezca un bien en trueque o venta declara bajo fe de juramento ser titular de dominio legítimo del mismo, que el artículo no es de procedencia ilícita y que no pesa sobre él gravamen ni impedimento legal para su libre disposición.',
              ),
              _buildSectionItem(
                '3. Revisión y Aceptación en Persona ("Como Está")',
                'Las partes reconocen que las transacciones e intercambios se efectúan en la modalidad "ad-corpus" o en el estado en que se encuentran los bienes tras la inspección física directa que realicen mutuamente los usuarios. ChiviMarket queda totalmente exenta de reclamos por vicios redhibitorios, fallas de funcionamiento o disconformidad posterior.',
              ),
              _buildSectionItem(
                '4. Consejos de Seguridad Física',
                'ChiviMarket recomienda expresamente realizar las entregas o intercambios de mercadería en lugares públicos, concurridos y durante horarios diurnos para salvaguardar la seguridad de los vecinos.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSubscriptionsTab(bool isDark, Color primaryColor) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSummaryBox(
          'Planes y Suscripciones para Comercios',
          'Las suscripciones comerciales otorgan acceso a funcionalidades digitales de mayor alcance (publicación de locales, límites de catálogo, mapas destacados). El pago no implica sociedad ni garantía de ventas.',
          Icons.verified,
          Colors.greenAccent,
        ),
        GlassContainer(
          borderRadius: 20,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionItem(
                '1. Alcance de los Planes de Suscripción',
                'ChiviMarket ofrece a comerciantes y emprendedores planes de membresía periódicos destinados a ampliar el volumen de publicación y visibilidad en la plataforma. Los planes habilitan herramientas tecnológicas de software y no constituyen garantía de éxito comercial ni de volumen de ventas.',
              ),
              _buildSectionItem(
                '2. Facturación y Formas de Pago',
                'Los abonos se abonan conforme a los períodos acordados (mensual, semestral o anual) a través de las pasarelas de pago habilitadas o transferencias bancarias oficiales. Las tarifas vigentes se informan con transparencia en el panel de control del comerciante.',
              ),
              _buildSectionItem(
                '3. Upgrades, Downgrades y Cancelaciones',
                'El titular puede solicitar la mejora o cancelación de su plan en cualquier momento desde su panel de control. En caso de baja, el servicio permanecerá activo hasta el fin del ciclo de facturación abonado, sin reintegro retroactivo.',
              ),
              _buildSectionItem(
                '4. Cumplimiento Normativo del Comerciante',
                'El titular de la cuenta comercial es el único responsable por el cumplimiento de sus obligaciones impositivas, tributarias (AFIP / ARBA) y comerciales locales derivadas de sus ventas a terceros.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildPrivacyTab(bool isDark, Color primaryColor) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSummaryBox(
          'Protección de Datos Personales (Ley 25.326)',
          'Tus datos están protegidos. No vendemos ni compartimos tu información personal con anunciantes externos. Podés solicitar la rectificación o eliminación de tu cuenta en cualquier momento.',
          Icons.shield,
          Colors.purpleAccent,
        ),
        GlassContainer(
          borderRadius: 20,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionItem(
                '1. Recolección y Uso de la Información',
                'ChiviMarket recopila únicamente los datos necesarios para brindar el servicio (correo electrónico, nombre público, número de contacto comercial y geolocalización de tiendas facilitada voluntariamente por el comerciante).',
              ),
              _buildSectionItem(
                '2. Finalidad del Tratamiento',
                'Los datos son utilizados para permitir el inicio de sesión, contactar al comercio a través de WhatsApp o medios provistos, y gestionar las preferencias de favoritos y cupones.',
              ),
              _buildSectionItem(
                '3. Ejercicio de Derechos de Acceso y Supresión',
                'Conforme a la Ley Nacional 25.326 de Protección de los Datos Personales, todo titular podrá solicitar de forma gratuita el acceso, rectificación o eliminación total de sus datos personales de nuestras bases comunicándose con el soporte oficial de ChiviMarket.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
