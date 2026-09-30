# Plantillas Oficiales de Correo Electrónico — Alianza Chaclacayo

Este documento contiene las plantillas HTML responsivas listas para ser utilizadas con **Resend** o copiadas directamente en el panel de **Supabase (Authentication > Email Templates)**.

---

## 1. Configuración de Resend (Solución al error de envío)

> [!IMPORTANT]
> **¿Por qué fallaba el envío con Resend?**
> Con la dirección de prueba predeterminada `onboarding@resend.dev`, Resend por seguridad **solo permite enviar correos a la dirección del dueño de la cuenta de Resend**. Al intentar enviar a otros correos de miembros o alumnos (como Gmail o Hotmail), Resend rechaza la petición con error 403/422.
>
> **Solución:**
> 1. Ingresar a [resend.com/domains](https://resend.com/domains).
> 2. Agregar el dominio de la iglesia (ej. `alianzachaclacayo.pe` o subdominio `mail.alianzachaclacayo.pe`).
> 3. Agregar los registros DNS (DKIM / SPF) que indica Resend en su proveedor de dominio.
> 4. Cambiar en `AppConstants.resendFromEmail` a: `Alianza Chaclacayo <notificaciones@alianzachaclacayo.pe>`.
>
> Mientras tanto, para el restablecimiento de contraseñas, la app utiliza la infraestructura nativa de **Supabase Auth**, que sí envía correos a cualquier destinatario.

---

## 2. Plantilla 1: Restablecimiento de Contraseña (Password Reset)

```html
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Restablecer Contraseña</title>
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; background-color: #F8FAFC; margin: 0; padding: 20px; color: #1E293B; }
    .container { max-width: 560px; margin: 0 auto; background: #ffffff; border-radius: 20px; overflow: hidden; box-shadow: 0 4px 24px rgba(0,0,0,0.06); }
    .header { background: linear-gradient(135deg, #00173B 0%, #032B69 100%); padding: 36px 24px; text-align: center; color: #ffffff; }
    .header h1 { margin: 0; font-size: 22px; font-weight: 700; letter-spacing: 0.3px; }
    .header p { margin: 6px 0 0; color: #DAE2FB; font-size: 12px; }
    .content { padding: 32px 28px; line-height: 1.6; }
    .btn-container { text-align: center; margin: 24px 0; }
    .btn { display: inline-block; background-color: #00173B; color: #ffffff !important; padding: 14px 32px; border-radius: 12px; font-weight: 700; text-decoration: none; font-size: 14px; box-shadow: 0 4px 12px rgba(0,23,59,0.25); }
    .notice { background: #FEF3C7; border-left: 4px solid #F59E0B; padding: 12px 16px; border-radius: 8px; font-size: 12px; color: #92400E; margin: 20px 0; }
    .footer { text-align: center; padding: 24px; font-size: 11px; color: #94A3B8; border-top: 1px solid #F1F5F9; background: #FAFBFD; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>Restablecimiento de Contraseña</h1>
      <p>Seguridad de Cuenta • Iglesia Alianza Chaclacayo</p>
    </div>
    <div class="content">
      <p>Paz de Cristo,</p>
      <p>Hemos recibido una solicitud para restablecer la contraseña de acceso a tu cuenta en la aplicación móvil y web de la <strong>Iglesia Alianza Chaclacayo</strong>.</p>
      <p>Para establecer una nueva contraseña segura, presiona el siguiente botón:</p>
      
      <div class="btn-container">
        <a href="{{ .ConfirmationURL }}" class="btn">Restablecer mi Contraseña</a>
      </div>

      <div class="notice">
        <strong>Importante:</strong> Este enlace tiene una vigencia limitada por tu seguridad. Si tú no realizaste esta solicitud, puedes ignorar este mensaje y tu contraseña actual permanecerá sin cambios.
      </div>

      <p style="font-size: 12px; color: #64748B; margin-top: 24px;">
        Si el botón no abre directamente, copia y pega el siguiente enlace en tu navegador:<br>
        <a href="{{ .ConfirmationURL }}" style="color: #032B69; word-break: break-all;">{{ .ConfirmationURL }}</a>
      </p>
    </div>
    <div class="footer">
      Alianza Cristiana y Misionera de Chaclacayo • Lima, Perú<br>
      Este es un correo automático de seguridad del sistema.
    </div>
  </div>
</body>
</html>
```

---

## 3. Plantilla 2: Apertura de Nuevo Ciclo Académico (Academia ABC)

```html
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Apertura de Nuevo Ciclo - Academia ABC</title>
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; background-color: #F8FAFC; margin: 0; padding: 20px; color: #1E293B; }
    .container { max-width: 580px; margin: 0 auto; background: #ffffff; border-radius: 20px; overflow: hidden; box-shadow: 0 4px 24px rgba(0,0,0,0.06); }
    .header { background: linear-gradient(135deg, #00173B 0%, #032B69 100%); padding: 36px 24px; text-align: center; color: #ffffff; }
    .badge { background: #F59E0B; color: #ffffff; font-weight: 700; font-size: 11px; padding: 5px 14px; border-radius: 20px; display: inline-block; margin-bottom: 10px; letter-spacing: 0.5px; }
    .header h1 { margin: 0; font-size: 22px; font-weight: 700; }
    .header p { margin: 6px 0 0; color: #DAE2FB; font-size: 13px; }
    .content { padding: 32px 28px; line-height: 1.6; }
    .cycle-card { background: #EFF6FF; border: 1px solid #BFDBFE; border-radius: 14px; padding: 20px; margin: 20px 0; }
    .btn-container { text-align: center; margin: 24px 0; }
    .btn { display: inline-block; background-color: #00173B; color: #ffffff !important; padding: 14px 32px; border-radius: 12px; font-weight: 700; text-decoration: none; font-size: 14px; box-shadow: 0 4px 12px rgba(0,23,59,0.25); }
    .footer { text-align: center; padding: 24px; font-size: 11px; color: #94A3B8; border-top: 1px solid #F1F5F9; background: #FAFBFD; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <div class="badge">ACADEMIA ABC • MATRÍCULAS ABIERTAS</div>
      <h1>¡Iniciamos Nuevo Ciclo de Formación!</h1>
      <p>Crecimiento Espiritual y Discipulado Bíblico</p>
    </div>
    <div class="content">
      <p>Estimado(a) hermano(a),</p>
      <p>Nos gozamos en anunciarte la apertura de inscripciones para el nuevo ciclo en la <strong>Academia ABC</strong> de nuestra iglesia.</p>
      
      <div class="cycle-card">
        <div style="font-size: 12px; color: #1E40AF; font-weight: 700; margin-bottom: 8px;">📅 FECHA DE INICIO DE CLASES: Próximo Domingo</div>
        <div style="font-size: 13px; color: #1E293B; margin-bottom: 8px;"><strong>Niveles y Cursos Disponibles:</strong></div>
        <ul style="margin: 0; padding-left: 20px; color: #00173B; font-weight: 600;">
          <li style="margin-bottom: 4px;">Nivel 1: Bautismo en Agua</li>
          <li style="margin-bottom: 4px;">Nivel 2: ABC Cristiano (Fundamentos de la Fe)</li>
          <li style="margin-bottom: 4px;">Nivel 3: Madurez Cristiana (Carácter y Discipulado)</li>
        </ul>
      </div>

      <p>Recuerda que los cupos son limitados por aula para garantizar una enseñanza personalizada con los maestros.</p>

      <div class="btn-container">
        <a href="https://alianza-chaclacayo.web.app" class="btn">Matricularme en la App Oficial</a>
      </div>

      <p style="margin-top: 24px; font-size: 12.5px; color: #64748B;">
        <em>"Creced en la gracia y el conocimiento de nuestro Señor y Salvador Jesucristo."</em> — 2 Pedro 3:18
      </p>
    </div>
    <div class="footer">
      Coordinación de Academia ABC • Iglesia Alianza Chaclacayo<br>
      Consultas e informes con los maestros o secretaría pastoral.
    </div>
  </div>
</body>
</html>
```
