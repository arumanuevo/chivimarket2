-- Script para asignar coordenadas aleatorias dentro de Chivilcoy a negocios existentes
-- Rango de Latitud Centro: -34.9153 a -34.8753
-- Rango de Longitud Centro: -60.0372 a -59.9972

UPDATE businesses
SET 
  latitude = ROUND(-34.9153 + (RAND() * 0.0400), 7),
  longitude = ROUND(-60.0372 + (RAND() * 0.0400), 7)
WHERE latitude IS NULL OR longitude IS NULL;

-- Para asegurar que los negocios "online" no tengan coordenadas (opcional, si quieres mantener la coherencia)
UPDATE businesses
SET 
  latitude = NULL,
  longitude = NULL
WHERE modality = 'online';
