import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';

class ResendEmailService {
  static const String _functionEndpoint = '${AppConstants.supabaseUrl}/functions/v1/send-email';

  /// Base method to send any email via Supabase Edge Function with Gmail SMTP
  static Future<bool> sendEmail({
    required String to,
    required String subject,
    required String html,
    String? text,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_functionEndpoint),
        headers: {
          'Authorization': 'Bearer ${AppConstants.supabaseAnonKey}',
          'apikey': AppConstants.supabaseAnonKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'to': to,
          'subject': subject,
          'html': html,
          'text': text,
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        debugPrint('Email sent successfully via Gmail SMTP to $to (Status: ${response.statusCode})');
        return true;
      } else {
        debugPrint('Email Function Error: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Exception while sending email: $e');
      return false;
    }
  }

  /// 1. Correo de Bienvenida al Registrarse
  static Future<bool> sendWelcomeEmail({
    required String to,
    required String name,
    required String dni,
    required String network,
  }) async {
    final html = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <style>
    body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #F8FAFC; margin: 0; padding: 20px; color: #1E293B; }
    .container { max-width: 580px; margin: 0 auto; background: #ffffff; border-radius: 20px; overflow: hidden; box-shadow: 0 4px 20px rgba(0,0,0,0.08); }
    .header { background: linear-gradient(135deg, #00173B 0%, #032B69 100%); padding: 36px 24px; text-align: center; color: #ffffff; }
    .header h1 { margin: 0; font-size: 22px; letter-spacing: 0.5px; }
    .header p { margin: 6px 0 0; font-size: 13px; color: #DAE2FB; }
    .content { padding: 30px 24px; }
    .card { background: #F1F5F9; border-radius: 14px; padding: 18px; margin: 20px 0; }
    .card-row { display: flex; justify-content: space-between; margin-bottom: 8px; font-size: 13px; }
    .card-label { color: #64748B; font-weight: 600; }
    .card-value { color: #00173B; font-weight: bold; }
    .footer { text-align: center; padding: 20px; font-size: 11px; color: #94A3B8; border-top: 1px solid #E2E8F0; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>¡Bienvenido a la Familia!</h1>
      <p>Iglesia Alianza Cristiana y Misionera de Chaclacayo</p>
    </div>
    <div class="content">
      <p>Estimado(a) <strong>$name</strong>,</p>
      <p>Nos alegra darte la más cordial bienvenida a nuestra comunidad de fe. Tu cuenta ha sido registrada correctamente en nuestra plataforma digital.</p>
      
      <div class="card">
        <div class="card-row">
          <span class="card-label">Documento (DNI):</span>
          <span class="card-value">$dni</span>
        </div>
        <div class="card-row">
          <span class="card-label">Red Eclesiástica:</span>
          <span class="card-value">$network</span>
        </div>
      </div>

      <p>A través de la aplicación podrás acceder a tu carnet digital de membresía, matricularte en la Academia ABC, enviar tus peticiones de oración y reportar tus diezmos y ofrendas.</p>
      <p style="margin-top: 24px;"><em>"Porque donde están dos o tres congregados en mi nombre, allí estoy yo en medio de ellos."</em> — Mateo 18:20</p>
    </div>
    <div class="footer">
      Alianza Cristiana y Misionera de Chaclacayo • Lima, Perú<br>
      Este es un correo automático enviado desde la plataforma oficial.
    </div>
  </div>
</body>
</html>
''';

    return sendEmail(
      to: to,
      subject: '¡Bienvenido(a) a la Iglesia Alianza Chaclacayo!',
      html: html,
    );
  }

  /// 2. Confirmación de Matrícula en Academia ABC
  static Future<bool> sendEnrollmentConfirmation({
    required String to,
    required String studentName,
    required String courseTitle,
    required String courseCode,
    required String schedule,
    required String level,
    required String teacherName,
    required String cycleCode,
    bool isVirtual = false,
    String? virtualLink,
  }) async {
    final html = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <style>
    body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #F8FAFC; margin: 0; padding: 20px; color: #1E293B; }
    .container { max-width: 580px; margin: 0 auto; background: #ffffff; border-radius: 20px; overflow: hidden; box-shadow: 0 4px 20px rgba(0,0,0,0.08); }
    .header { background: linear-gradient(135deg, #00173B 0%, #032B69 100%); padding: 32px 24px; text-align: center; color: #ffffff; }
    .badge { display: inline-block; background: #16A34A; color: #ffffff; font-size: 11px; font-weight: bold; padding: 4px 12px; border-radius: 20px; margin-bottom: 10px; }
    .content { padding: 28px 24px; }
    .course-card { background: #F8FAFC; border: 1px solid #E2E8F0; border-radius: 14px; padding: 18px; margin: 18px 0; }
    .info-item { margin-bottom: 10px; font-size: 13.5px; }
    .info-label { color: #64748B; font-weight: 600; font-size: 12px; }
    .info-val { color: #00173B; font-weight: bold; font-size: 14px; }
    .footer { text-align: center; padding: 20px; font-size: 11px; color: #94A3B8; border-top: 1px solid #E2E8F0; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <div class="badge">MATRÍCULA CONFIRMADA</div>
      <h1 style="margin:0; font-size: 20px;">Academia Bíblica Cristiana (ABC)</h1>
      <p style="margin: 4px 0 0; color: #DAE2FB; font-size: 12px;">Ciclo Académico: $cycleCode</p>
    </div>
    <div class="content">
      <p>Hola <strong>$studentName</strong>,</p>
      <p>Tu inscripción ha sido procesada con éxito. Aquí tienes el resumen de tu clase:</p>
      
      <div class="course-card">
        <div class="info-item">
          <div class="info-label">MATERIA:</div>
          <div class="info-val">$courseCode - $courseTitle</div>
        </div>
        <div class="info-item">
          <div class="info-label">NIVEL & MODALIDAD:</div>
          <div class="info-val">$level • ${isVirtual ? 'Virtual' : 'Presencial'}</div>
        </div>
        <div class="info-item">
          <div class="info-label">HORARIO DE CLASES:</div>
          <div class="info-val">$schedule</div>
        </div>
        <div class="info-item">
          <div class="info-label">DOCENTE ASIGNADO:</div>
          <div class="info-val">$teacherName</div>
        </div>
        ${isVirtual && virtualLink != null && virtualLink.isNotEmpty ? '<div class="info-item"><div class="info-label">ENLACE DE ACCESO VIRTUAL:</div><div class="info-val"><a href="$virtualLink" style="color: #2563EB;">$virtualLink</a></div></div>' : ''}
      </div>

      <p style="font-size: 12.5px; color: #475569;">Podrás encontrar los materiales de clase, control de asistencias y registro de notas directamente desde el módulo de la Academia en la app.</p>
    </div>
    <div class="footer">
      Coordinación Académica ABC • IACyM Chaclacayo
    </div>
  </div>
</body>
</html>
''';

    return sendEmail(
      to: to,
      subject: 'Confirmación de Matrícula ABC: $courseTitle ($cycleCode)',
      html: html,
    );
  }

  /// 3. Envío de Constancia / Certificado de Aprobación
  static Future<bool> sendCertificateEmail({
    required String to,
    required String studentName,
    required String courseTitle,
    required String subjectCode,
    required dynamic grade,
    required String cycleCode,
  }) async {
    final html = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <style>
    body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #F8FAFC; margin: 0; padding: 20px; color: #1E293B; }
    .container { max-width: 580px; margin: 0 auto; background: #ffffff; border-radius: 20px; overflow: hidden; box-shadow: 0 4px 20px rgba(0,0,0,0.08); }
    .header { background: linear-gradient(135deg, #00173B 0%, #032B69 100%); padding: 32px 24px; text-align: center; color: #ffffff; }
    .content { padding: 28px 24px; }
    .diploma-badge { background: #F59E0B; color: #ffffff; font-weight: bold; font-size: 11px; padding: 4px 14px; border-radius: 20px; display: inline-block; margin-bottom: 8px; }
    .grade-box { background: #ECFDF5; border: 2px solid #86EFAC; border-radius: 14px; padding: 18px; text-align: center; margin: 20px 0; }
    .grade-num { font-size: 32px; font-weight: bold; color: #16A34A; }
    .footer { text-align: center; padding: 20px; font-size: 11px; color: #94A3B8; border-top: 1px solid #E2E8F0; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <div class="diploma-badge">CERTIFICADO OFICIAL</div>
      <h1 style="margin:0; font-size: 20px;">¡Felicitaciones por culminar tu curso!</h1>
      <p style="margin: 4px 0 0; color: #DAE2FB; font-size: 12px;">Academia Bíblica Cristiana (ABC)</p>
    </div>
    <div class="content">
      <p>Estimado(a) <strong>$studentName</strong>,</p>
      <p>Es un gozo para el equipo pastoral y docente comunicarte que has culminado y aprobado satisfactoriamente la materia:</p>
      
      <h3 style="color: #00173B; text-align: center; margin: 16px 0; font-size: 18px;">"$courseTitle" ($subjectCode)</h3>

      <div class="grade-box">
        <div style="font-size: 12px; color: #166534; font-weight: 600;">CALIFICACIÓN FINAL OBTENIDA</div>
        <div class="grade-num">$grade / 20</div>
        <div style="font-size: 12px; color: #15803D; font-weight: bold;">ESTADO: APROBADO SATISFACTORIAMENTE</div>
      </div>

      <p style="font-size: 12.5px; color: #475569;">Puedes descargar e imprimir tu Diploma oficial en alta resolución desde el menú de <strong>Mi Historial</strong> en la aplicación móvil.</p>
    </div>
    <div class="footer">
      Academia Bíblica Cristiana (ABC) • IACyM Chaclacayo
    </div>
  </div>
</body>
</html>
''';

    return sendEmail(
      to: to,
      subject: 'Certificado de Aprobación ABC: $courseTitle (Nota: $grade)',
      html: html,
    );
  }

  /// 4. Confirmación de Reporte de Diezmo u Ofrenda
  static Future<bool> sendTithingConfirmation({
    required String to,
    required String memberName,
    required String amount,
    required String type,
    required String bank,
  }) async {
    final html = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <style>
    body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #F8FAFC; margin: 0; padding: 20px; color: #1E293B; }
    .container { max-width: 580px; margin: 0 auto; background: #ffffff; border-radius: 20px; overflow: hidden; box-shadow: 0 4px 20px rgba(0,0,0,0.08); }
    .header { background: linear-gradient(135deg, #00173B 0%, #032B69 100%); padding: 32px 24px; text-align: center; color: #ffffff; }
    .content { padding: 28px 24px; }
    .receipt { background: #F8FAFC; border: 1px solid #CBD5E1; border-radius: 14px; padding: 18px; margin: 18px 0; }
    .receipt-row { display: flex; justify-content: space-between; margin-bottom: 8px; font-size: 13px; }
    .footer { text-align: center; padding: 20px; font-size: 11px; color: #94A3B8; border-top: 1px solid #E2E8F0; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1 style="margin:0; font-size: 20px;">Constancia de Recepción de Aporte</h1>
      <p style="margin: 4px 0 0; color: #DAE2FB; font-size: 12px;">Tesorería • Alianza Chaclacayo</p>
    </div>
    <div class="content">
      <p>Estimado(a) <strong>$memberName</strong>,</p>
      <p>Hemos recibido tu reporte de contribución. El equipo de tesorería procederá a la conciliación correspondiente.</p>
      
      <div class="receipt">
        <div class="receipt-row">
          <span style="color:#64748B;">Concepto:</span>
          <span style="font-weight:bold; color:#00173B;">$type</span>
        </div>
        <div class="receipt-row">
          <span style="color:#64748B;">Monto:</span>
          <span style="font-weight:bold; color:#16A34A; font-size: 16px;">S/ $amount</span>
        </div>
        <div class="receipt-row">
          <span style="color:#64748B;">Medio de Pago:</span>
          <span style="font-weight:bold; color:#00173B;">$bank</span>
        </div>
      </div>

      <p style="font-size: 12.5px; color: #475569;"><em>"Cada uno dé como propuso en su corazón: no con tristeza, ni por necesidad, porque Dios ama al dador alegre."</em> — 2 Corintios 9:7</p>
    </div>
    <div class="footer">
      Ministerio de Mayordomía y Tesorería • IACyM Chaclacayo
    </div>
  </div>
</body>
</html>
''';

    return sendEmail(
      to: to,
      subject: 'Constancia de Reporte de $type (S/ $amount)',
      html: html,
    );
  }

  /// 5. Confirmación de Petición de Oración
  static Future<bool> sendPrayerRequestConfirmation({
    required String to,
    required String authorName,
    required String title,
    required String category,
  }) async {
    final html = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <style>
    body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #F8FAFC; margin: 0; padding: 20px; color: #1E293B; }
    .container { max-width: 580px; margin: 0 auto; background: #ffffff; border-radius: 20px; overflow: hidden; box-shadow: 0 4px 20px rgba(0,0,0,0.08); }
    .header { background: linear-gradient(135deg, #00173B 0%, #032B69 100%); padding: 32px 24px; text-align: center; color: #ffffff; }
    .content { padding: 28px 24px; }
    .prayer-card { background: #EFF6FF; border: 1px solid #BFDBFE; border-radius: 14px; padding: 18px; margin: 18px 0; }
    .footer { text-align: center; padding: 20px; font-size: 11px; color: #94A3B8; border-top: 1px solid #E2E8F0; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1 style="margin:0; font-size: 20px;">Petición de Oración Registrada</h1>
      <p style="margin: 4px 0 0; color: #DAE2FB; font-size: 12px;">Mañanas de Oración • Alianza Chaclacayo</p>
    </div>
    <div class="content">
      <p>Paz de Cristo, <strong>$authorName</strong>,</p>
      <p>Tu petición ha sido recibida y se ha sumado a nuestro muro de intercesión comunitaria.</p>
      
      <div class="prayer-card">
        <div style="font-size: 11px; color: #1D4ED8; font-weight: bold; margin-bottom: 4px;">CATEGORÍA: ${category.toUpperCase()}</div>
        <div style="font-size: 15px; font-weight: bold; color: #1E3A8A;">"$title"</div>
      </div>

      <p style="font-size: 12.5px; color: #475569;">Nuestros hermanos e intercesores estarán clamando por tu causa en las Mañanas de Oración.</p>
      <p style="font-size: 12.5px; color: #475569;"><em>"La oración eficaz del justo puede mucho."</em> — Santiago 5:16</p>
    </div>
    <div class="footer">
      Ministerio de Oración e Intercesión • IACyM Chaclacayo
    </div>
  </div>
</body>
</html>
''';

    return sendEmail(
      to: to,
      subject: 'Nos unimos en oración: $title',
      html: html,
    );
  }

  /// 7. Correo de Restablecimiento de Contraseña
  static Future<bool> sendPasswordResetEmail({
    required String to,
    required String name,
    required String resetLink,
  }) async {
    final html = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <style>
    body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #F8FAFC; margin: 0; padding: 20px; color: #1E293B; }
    .container { max-width: 580px; margin: 0 auto; background: #ffffff; border-radius: 20px; overflow: hidden; box-shadow: 0 4px 20px rgba(0,0,0,0.08); }
    .header { background: linear-gradient(135deg, #00173B 0%, #032B69 100%); padding: 32px 24px; text-align: center; color: #ffffff; }
    .content { padding: 30px 24px; line-height: 1.6; }
    .btn { display: inline-block; background: #00173B; color: #ffffff !important; padding: 14px 28px; border-radius: 12px; font-weight: bold; text-decoration: none; font-size: 14px; margin: 18px 0; }
    .notice { background: #FEF3C7; border-left: 4px solid #F59E0B; padding: 12px 16px; border-radius: 8px; font-size: 12px; color: #92400E; margin: 16px 0; }
    .footer { text-align: center; padding: 20px; font-size: 11px; color: #94A3B8; border-top: 1px solid #E2E8F0; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1 style="margin:0; font-size: 20px;">Restablecimiento de Contraseña</h1>
      <p style="margin: 4px 0 0; color: #DAE2FB; font-size: 12px;">Seguridad • Alianza Chaclacayo</p>
    </div>
    <div class="content">
      <p>Hola <strong>$name</strong>,</p>
      <p>Recibimos una solicitud para restablecer la contraseña de tu cuenta en la aplicación de la <strong>Iglesia Alianza Chaclacayo</strong>.</p>
      <p>Para crear una nueva contraseña, haz clic en el siguiente botón:</p>
      
      <div style="text-align: center;">
        <a href="$resetLink" class="btn">Restablecer mi Contraseña</a>
      </div>

      <div class="notice">
        <strong>Nota de seguridad:</strong> Este enlace expirará pronto. Si tú no solicitaste este cambio, puedes ignorar este mensaje de forma segura.
      </div>

      <p style="font-size: 12px; color: #64748B;">Si el botón no funciona, copia y pega este enlace en tu navegador:<br><a href="$resetLink" style="color: #032B69; word-break: break-all;">$resetLink</a></p>
    </div>
    <div class="footer">
      Alianza Cristiana y Misionera de Chaclacayo • Soporte Técnico<br>
      Este es un correo automático del sistema de seguridad.
    </div>
  </div>
</body>
</html>
''';

    return sendEmail(
      to: to,
      subject: 'Restablecer contraseña - Alianza Chaclacayo',
      html: html,
    );
  }

  /// 8. Correo de Apertura de Nuevo Ciclo Académico (Academia ABC)
  static Future<bool> sendNewCycleAnnouncementEmail({
    required String to,
    required String memberName,
    required String cycleName,
    required String startDate,
    List<String>? coursesAvailable,
  }) async {
    final html = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <style>
    body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #F8FAFC; margin: 0; padding: 20px; color: #1E293B; }
    .container { max-width: 580px; margin: 0 auto; background: #ffffff; border-radius: 20px; overflow: hidden; box-shadow: 0 4px 20px rgba(0,0,0,0.08); }
    .header { background: linear-gradient(135deg, #00173B 0%, #032B69 100%); padding: 36px 24px; text-align: center; color: #ffffff; }
    .badge { background: #F59E0B; color: #ffffff; font-weight: bold; font-size: 11px; padding: 4px 12px; border-radius: 20px; display: inline-block; margin-bottom: 8px; }
    .content { padding: 30px 24px; line-height: 1.6; }
    .cycle-card { background: #EFF6FF; border: 1px solid #BFDBFE; border-radius: 14px; padding: 18px; margin: 20px 0; }
    .btn { display: inline-block; background: #00173B; color: #ffffff !important; padding: 14px 28px; border-radius: 12px; font-weight: bold; text-decoration: none; font-size: 14px; margin: 16px 0; }
    .footer { text-align: center; padding: 20px; font-size: 11px; color: #94A3B8; border-top: 1px solid #E2E8F0; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <div class="badge">ACADEMIA ABC • MATRÍCULAS ABIERTAS</div>
      <h1 style="margin:0; font-size: 22px;">¡Iniciamos Nuevo Ciclo de Formación!</h1>
      <p style="margin: 6px 0 0; color: #DAE2FB; font-size: 13px;">$cycleName</p>
    </div>
    <div class="content">
      <p>Estimado(a) <strong>$memberName</strong>,</p>
      <p>Nos gozamos en anunciarte la apertura de inscripciones para el nuevo ciclo de discipulado y crecimiento espiritual en la <strong>Academia ABC</strong> de nuestra iglesia.</p>
      
      <div class="cycle-card">
        <div style="font-size: 13px; color: #1E40AF; font-weight: bold; margin-bottom: 8px;">📅 FECHA DE INICIO: $startDate</div>
        <p style="margin: 0; font-size: 13px; color: #334155; line-height: 1.5;">
          Los cursos, horarios y modalidades disponibles ya se encuentran publicados en nuestra aplicación. Te invitamos a ingresar para revisar las opciones y realizar tu inscripción.
        </p>
      </div>

      <p>Los cupos son limitados. Puedes reservar tu matrícula directamente desde tu celular ingresando a la sección <strong>Academia ABC</strong> en nuestra aplicación oficial.</p>

      <div style="text-align: center; margin: 24px 0;">
        <a href="https://alianza-chaclacayo.web.app" class="btn">Matricularme en la App</a>
      </div>

      <p style="margin-top: 20px; font-size: 12.5px; color: #64748B;"><em>"Creced en la gracia y el conocimiento de nuestro Señor y Salvador Jesucristo."</em> — 2 Pedro 3:18</p>
    </div>
    <div class="footer">
      Coordinación de Academia ABC • Iglesia Alianza Chaclacayo<br>
      Consultas e informes con los maestros o secretaría pastoral.
    </div>
  </div>
</body>
</html>
''';

    return sendEmail(
      to: to,
      subject: '🎓 ¡Inscripciones Abiertas: $cycleName! - Academia ABC',
      html: html,
    );
  }
}
