[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$project = Split-Path -Parent $PSScriptRoot
$atlasPath = Join-Path $project 'docs/vehicle-colors/repaint-atlas.png'
$atlas = [Drawing.Bitmap]::FromFile($atlasPath)
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System.Drawing;
public static class VehicleSpriteBounds {
    public static Rectangle Find(Bitmap image, Rectangle cell) {
        int left = cell.Right, top = cell.Bottom, right = cell.Left, bottom = cell.Top;
        for (int y = cell.Top; y < cell.Bottom; y++) {
            for (int x = cell.Left; x < cell.Right; x++) {
                // Ignore nearly invisible alpha noise when measuring the sprite.
                if (image.GetPixel(x, y).A < 16) continue;
                left = System.Math.Min(left, x); top = System.Math.Min(top, y);
                right = System.Math.Max(right, x); bottom = System.Math.Max(bottom, y);
            }
        }
        if (left > right) throw new System.Exception("Empty vehicle atlas cell");
        return Rectangle.FromLTRB(left, top, right + 1, bottom + 1);
    }
}
'@
$colors = @('laranja', 'azul', 'preto', 'branco')
$names = @('caminhonete_cima', 'caminhonete_lateral', 'moto_cima', 'moto_lateral')
try {
    for ($column = 0; $column -lt 4; $column++) {
        for ($row = 0; $row -lt 4; $row++) {
            $left = [int][Math]::Round($column * $atlas.Width / 4.0)
            $top = [int][Math]::Round($row * $atlas.Height / 4.0)
            $right = [int][Math]::Round(($column + 1) * $atlas.Width / 4.0)
            $bottom = [int][Math]::Round(($row + 1) * $atlas.Height / 4.0)
            $cell = [Drawing.Rectangle]::FromLTRB($left, $top, $right, $bottom)
            $bounds = [VehicleSpriteBounds]::Find($atlas, $cell)
            $sprite = $atlas.Clone($bounds, [Drawing.Imaging.PixelFormat]::Format32bppArgb)
            try {
                $destination = Join-Path $project ('assets/vehicles/players/' + $colors[$column] + '/' + $names[$row] + '_' + $colors[$column] + '.png')
                $sprite.Save($destination, [Drawing.Imaging.ImageFormat]::Png)
            } finally { $sprite.Dispose() }
        }
    }
} finally { $atlas.Dispose() }
