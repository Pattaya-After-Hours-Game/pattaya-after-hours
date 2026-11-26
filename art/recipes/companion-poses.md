# Companion animation source notes

The built-in ImageGen tool used the original runtime sprites as references.
The generated art was aligned to the original atlas pivots for packing.

## Capybara

The [four aligned pose cells](../sources/customer-capybara-poses.png) follow the
existing standing frame. The generated crouch and sit supply the hindquarters,
with the original head, front paws, customer, and leash kept in place. Closed
eyelids were finished at the runtime pixel size.

> Use case: precise-object-edit. Produce a transparent sprite pose reference sheet for the capybara in the input. Output three isolated full-body versions of ONLY the capybara in well-separated horizontal columns of equal size, with identical head proportions and exact palette and pixel-art rendering as input. Left: same standing pose but visibly closed dark eyelid. Middle: halfway lowering hindquarters, front paws planted. Right: fully seated on its haunches with hind paws tucked, front legs still straight/on the ground, head held up like the original. All three face right with the exact same three-quarter angle as the original. Match the short rounded ears, squared muzzle, amber fur and dark teal chest/body harness. Fur shading should match clusters of the pixel art input. No man or leash, no labels, no additional entities, no frames or grid lines, no shadow. True transparent background.

## Rainbow duo

The [aligned kiss frame](../sources/customer-rainbow-duo-kiss.png) follows the
existing idle frame. The heart is drawn by Godot.

> Use case: identity-preserve. Create one transparent full-body 2D pixel-art game sprite frame, a short affectionate closed-mouth kiss between these two adult male partners. Exact same two men, short man with dark hair/beard/glasses and colorful shirt still holding their little orange dog at his chest, tall red-haired bearded man in open plaid shirt over gray rainbow T-shirt bends left at his torso and slightly at his knees in profile so their lips actually meet. The shorter man tips his face up and right. Their eyes close softly. Keep the four sandals as close as possible to their exact original screen positions and same shared floor baseline. Preserve the exact outfits, body types, dog, relative sizes, plum outlines, warm highlights, and crisp authentic pixel-art clustered color/shadows of the reference. Match reference silhouettes from waist down and retain the frame's original margins and framing. All figures and shoes completely visible, true transparent pixels around and between figures. No floor or backdrop, no letters or hearts.

### Capybara lighting match

Both rainbow duo frames were repainted with the built-in ImageGen tool, using
the existing duo poses for composition and an enlarged view of the resting
capybara customer for rendering. The [idle source](../sources/customer-rainbow-duo.png)
is normalized by the packer. The [kiss source](../sources/customer-rainbow-duo-kiss.png)
is pre-aligned to the same floor baseline in its 160 × 192 cell. The transparent
cutouts use the same alpha threshold and nearest-neighbor sampling as the
other patrons.

> Image 1 is a two-pose game sprite to edit, idle then kiss. Image 2 is an enlarged crop of the actual capybara customer sprite, the sole style reference. Match its distinctive directional pixelated outline: VISIBLE pale butter-yellow and amber stair-step pixels in a broken rim on the upper and screen-left edges of hair, shoulders, arms, shorts, calves and sandal toe edges; on opposite screen-right edges use a much subtler teal/cyan reflected light in sparse pixels. The brightest gold edge flecks should read nearly white, as on the capybara customer's hair and shoulder. The bright pixels must be ON the silhouette, one runtime pixel wide, with breaks that reveal the deep aubergine contour. Keep them legible when shrunk to 180 px tall. Copy its warm terracotta shadows, deep wine/charcoal and modest handcrafted pixel clusters. Keep the couple's exact same faces, four feet, poses, rainbow clothes and little orange dog, separate left and right cells, aligned floor line. Preserve true alpha outside both sprites. No continuous white sticker border, hazy halo, floor, lettering, or bonus effects. Focus on transferring the reference’s outline and lighting, with the original poses and composition.
