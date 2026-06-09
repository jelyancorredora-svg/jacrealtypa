-- =====================================================
-- JAC REALTY — Supabase Schema
-- Ejecutar en: Supabase > SQL Editor
-- =====================================================

-- 1. SECUENCIA Y FUNCIÓN para código automático JR-001
CREATE SEQUENCE IF NOT EXISTS jac_realty_seq START 1;

CREATE OR REPLACE FUNCTION set_codigo_realty()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.codigo IS NULL THEN
    NEW.codigo := 'JR-' || LPAD(nextval('jac_realty_seq')::TEXT, 3, '0');
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 2. PROPIEDADES
CREATE TABLE IF NOT EXISTS propiedades_realty (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  codigo TEXT UNIQUE,
  titulo TEXT NOT NULL,
  descripcion TEXT,
  tipo_operacion TEXT CHECK (tipo_operacion IN ('Venta','Alquiler','Permuta')),
  tipo_inmueble TEXT CHECK (tipo_inmueble IN (
    'Apartamento','Casa','Penthouse','Local Comercial',
    'Oficina','Terreno','Estudio','Bodega'
  )),
  precio NUMERIC,
  moneda TEXT DEFAULT 'USD',
  area_m2 NUMERIC,
  habitaciones INT,
  banos INT,
  parqueos INT,
  piso INT,
  amoblado BOOLEAN DEFAULT false,
  provincia TEXT DEFAULT 'Panamá',
  distrito TEXT,
  corregimiento TEXT,
  direccion TEXT,
  lat NUMERIC,
  lng NUMERIC,
  estado TEXT DEFAULT 'Disponible' CHECK (estado IN (
    'Disponible','Reservado','En Proceso',
    'Vendido','Alquilado','Fuera de Mercado'
  )),
  publicar_web BOOLEAN DEFAULT false,
  destacado BOOLEAN DEFAULT false,
  imagenes JSONB DEFAULT '[]',
  video_url TEXT,
  caracteristicas JSONB DEFAULT '[]',
  notas_privadas TEXT,
  propietario_id UUID,
  comision_porcentaje NUMERIC DEFAULT 3,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TRIGGER IF NOT EXISTS trigger_codigo_realty
  BEFORE INSERT ON propiedades_realty
  FOR EACH ROW EXECUTE FUNCTION set_codigo_realty();

-- 3. CLIENTES
CREATE TABLE IF NOT EXISTS clientes_realty (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  nombre TEXT NOT NULL,
  apellido TEXT,
  cedula TEXT,
  telefono TEXT,
  whatsapp TEXT,
  email TEXT,
  tipo TEXT DEFAULT 'Comprador' CHECK (tipo IN (
    'Comprador','Arrendatario','Propietario','Inversionista','Co-broker'
  )),
  presupuesto_min NUMERIC,
  presupuesto_max NUMERIC,
  tipo_inmueble_busca TEXT,
  operacion_busca TEXT,
  zonas_interes JSONB DEFAULT '[]',
  hab_min INT,
  estado TEXT DEFAULT 'Activo' CHECK (estado IN (
    'Activo','En Negociación','Cerrado','Inactivo'
  )),
  origen TEXT CHECK (origen IN (
    'Referido','Instagram','WhatsApp','Web','Llamada','Otro'
  )),
  notas TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. NEGOCIACIONES
CREATE TABLE IF NOT EXISTS negociaciones_realty (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  titulo TEXT,
  tipo TEXT CHECK (tipo IN ('Venta','Alquiler','Permuta')),
  propiedad_id UUID REFERENCES propiedades_realty(id) ON DELETE SET NULL,
  cliente_id UUID REFERENCES clientes_realty(id) ON DELETE SET NULL,
  precio_oferta NUMERIC,
  precio_cierre NUMERIC,
  comision_estimada NUMERIC,
  etapa TEXT DEFAULT 'Contacto Inicial' CHECK (etapa IN (
    'Contacto Inicial','Visita Agendada','Visita Realizada',
    'Oferta Presentada','Negociando','Promesa Firmada',
    'Cerrado','Perdido'
  )),
  motivo_perdida TEXT,
  fecha_esperada DATE,
  notas TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. ACTIVIDADES
CREATE TABLE IF NOT EXISTS actividades_realty (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  tipo TEXT CHECK (tipo IN (
    'Llamada','Visita','Email','WhatsApp','Reunión','Nota'
  )),
  propiedad_id UUID,
  cliente_id UUID,
  negociacion_id UUID,
  descripcion TEXT,
  fecha TIMESTAMPTZ DEFAULT NOW()
);

-- 6. NOTAS
CREATE TABLE IF NOT EXISTS notas_realty (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  titulo TEXT,
  contenido TEXT,
  propiedad_id UUID,
  cliente_id UUID,
  tags JSONB DEFAULT '[]',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Desactivar RLS (activar con políticas luego)
ALTER TABLE propiedades_realty DISABLE ROW LEVEL SECURITY;
ALTER TABLE clientes_realty DISABLE ROW LEVEL SECURITY;
ALTER TABLE negociaciones_realty DISABLE ROW LEVEL SECURITY;
ALTER TABLE actividades_realty DISABLE ROW LEVEL SECURITY;
ALTER TABLE notas_realty DISABLE ROW LEVEL SECURITY;

-- Grant acceso público (anon key)
GRANT ALL ON propiedades_realty TO anon;
GRANT ALL ON clientes_realty TO anon;
GRANT ALL ON negociaciones_realty TO anon;
GRANT ALL ON actividades_realty TO anon;
GRANT ALL ON notas_realty TO anon;
GRANT USAGE, SELECT ON SEQUENCE jac_realty_seq TO anon;
