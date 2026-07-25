import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import '../../theme/app_theme.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: AppTheme.textPrimary,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Conditions d\'utilisation',
          style: GoogleFonts.outfit(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primary, AppTheme.primary.withAlpha(180)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Conditions Générales d\'Utilisation',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Dernière mise à jour : Mai 2026',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: Colors.white.withAlpha(200),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 2.h),

            _buildSection(
              '1. Acceptation des conditions',
              'En accédant à l\'application ZeHouse, développée et exploitée par WFTech, vous acceptez d\'être lié par les présentes Conditions Générales d\'Utilisation. Si vous n\'acceptez pas ces conditions, veuillez ne pas utiliser l\'application.',
            ),

            _buildSection(
              '2. Description du service',
              'ZeHouse est une plateforme immobilière et de services professionnels permettant aux utilisateurs de :\n\n• Publier et consulter des annonces immobilières (vente, location, meublé)\n• Contacter des professionnels du bâtiment et de l\'immobilier\n• Accéder à des services de proximité géolocalisés\n• Communiquer via messagerie intégrée\n• Gérer leurs favoris et leurs annonces',
            ),

            _buildSection(
              '3. Inscription et compte utilisateur',
              'Pour accéder aux fonctionnalités complètes de ZeHouse, vous devez créer un compte. Vous vous engagez à :\n\n• Fournir des informations exactes, complètes et à jour\n• Maintenir la confidentialité de vos identifiants de connexion\n• Notifier immédiatement ZEHOUSE de toute utilisation non autorisée de votre compte\n• Être responsable de toutes les activités effectuées depuis votre compte\n\nZEHOUSE se réserve le droit de suspendre ou supprimer tout compte en cas de violation des présentes conditions.',
            ),

            _buildSection(
              '4. Types de comptes et abonnements',
              'ZeHouse propose deux types de comptes :\n\n**Compte Standard (non-professionnel)**\n• Accès gratuit limité à 10 annonces et 5 favoris\n• Publication d\'annonces immobilières à 10\$ par publication\n• Accès à la consultation des annonces et aux services de proximité\n\n**Compte Professionnel**\n• Période d\'essai gratuite de 40 jours\n• Abonnements annuels selon la catégorie professionnelle (20\$ à 50\$/an)\n• Publications illimitées sans frais supplémentaires\n• Accès à toutes les fonctionnalités premium',
            ),

            _buildSection(
              '5. Paiements et remboursements',
              'Les paiements effectués sur ZeHouse sont traités via des prestataires de paiement sécurisés (CinetPay, Moneroo). En effectuant un paiement, vous acceptez :\n\n• Les frais indiqués au moment de la transaction\n• Que les abonnements sont non remboursables sauf disposition légale contraire\n• Que ZEHOUSE se réserve le droit de modifier les tarifs avec un préavis de 30 jours\n• Que vous êtes responsable de tous les frais liés à votre compte',
            ),

            _buildSection(
              '6. Contenu des annonces',
              'En publiant du contenu sur ZeHouse, vous déclarez et garantissez que :\n\n• Vous êtes propriétaire ou avez les droits nécessaires sur le contenu publié\n• Le contenu est exact, véridique et ne contient pas d\'informations trompeuses\n• Le contenu ne viole aucun droit de propriété intellectuelle de tiers\n• Le contenu ne contient pas de matériel illégal, offensant ou inapproprié\n\nZEHOUSE se réserve le droit de supprimer tout contenu jugé inapproprié sans préavis.',
            ),

            _buildSection(
              '7. Propriété intellectuelle',
              'L\'application ZeHouse, son design, ses fonctionnalités, son code source et tous les contenus créés par WFTech sont protégés par les lois sur la propriété intellectuelle. Vous n\'êtes pas autorisé à :\n\n• Reproduire, distribuer ou modifier l\'application sans autorisation écrite\n• Utiliser les marques, logos ou noms commerciaux de WFTech\n• Extraire ou réutiliser des données de l\'application à des fins commerciales\n• Créer des œuvres dérivées basées sur l\'application',
            ),

            _buildSection(
              '8. Confidentialité et données personnelles',
              'ZEHOUSE s\'engage à protéger vos données personnelles conformément aux lois applicables en matière de protection des données. Vos données sont utilisées pour :\n\n• Fournir et améliorer les services de ZeHouse\n• Personnaliser votre expérience utilisateur\n• Vous envoyer des communications relatives au service\n• Assurer la sécurité de la plateforme\n\nVos données ne sont jamais vendues à des tiers. Pour plus d\'informations, consultez notre Politique de Confidentialité.',
            ),

            _buildSection(
              '9. Limitation de responsabilité',
              'ZEHOUSE ne peut être tenu responsable :\n\n• De l\'exactitude des annonces publiées par les utilisateurs\n• Des transactions effectuées entre utilisateurs en dehors de la plateforme\n• Des interruptions de service dues à des causes indépendantes de notre volonté\n• Des dommages indirects résultant de l\'utilisation de l\'application\n\nL\'utilisation de ZeHouse est à vos propres risques. ZEHOUSE fournit le service "tel quel" sans garantie expresse ou implicite.',
            ),

            _buildSection(
              '10. Comportement des utilisateurs',
              'Vous vous engagez à ne pas utiliser ZeHouse pour :\n\n• Publier des annonces frauduleuses ou trompeuses\n• Harceler, menacer ou intimider d\'autres utilisateurs\n• Diffuser des logiciels malveillants ou tenter de pirater la plateforme\n• Contourner les mesures de sécurité de l\'application\n• Utiliser des robots ou scripts automatisés sans autorisation\n• Violer les lois locales, nationales ou internationales applicables',
            ),

            _buildSection(
              '11. Résiliation',
              'Vous pouvez résilier votre compte à tout moment depuis les paramètres de votre profil. ZEHOUSE peut résilier ou suspendre votre accès immédiatement, sans préavis, en cas de :\n\n• Violation des présentes conditions d\'utilisation\n• Comportement frauduleux ou abusif\n• Non-paiement des frais dus\n• Demande des autorités compétentes\n\nEn cas de résiliation, vos données seront conservées conformément à notre politique de rétention des données.',
            ),

            _buildSection(
              '12. Modifications des conditions',
              'ZEHOUSE se réserve le droit de modifier les présentes Conditions Générales d\'Utilisation à tout moment. Les modifications importantes seront notifiées par e-mail ou via une notification dans l\'application. La poursuite de l\'utilisation de ZeHouse après notification constitue votre acceptation des nouvelles conditions.',
            ),

            _buildSection(
              '13. Droit applicable',
              'Les présentes conditions sont régies par le droit applicable dans le pays d\'exploitation de WFTech. Tout litige relatif à l\'utilisation de ZeHouse sera soumis à la juridiction compétente du lieu du siège social de WFTech.',
            ),

            _buildSection(
              '14. Contact',
              'Pour toute question relative aux présentes Conditions Générales d\'Utilisation, vous pouvez contacter ZEHOUSE à :\n\n• E-mail : support@zehouse.com\n• Site web : www.zehouse.app\n\nNous nous engageons à répondre à vos demandes dans un délai de 5 jours ouvrables.',
            ),

            SizedBox(height: 2.h),

            // Copyright footer
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                children: [
                  Text(
                    '© 2026 WFTech. Tous droits réservés.',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ZeHouse est une marque déposée de WFTech.',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: AppTheme.muted,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            SizedBox(height: 3.h),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: AppTheme.textSecondary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
        ],
      ),
    );
  }
}
