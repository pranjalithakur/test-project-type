// placeholder migration to satisfy anchor layout
import * as anchor from "@coral-xyz/anchor";

export default async function main(provider: anchor.AnchorProvider) {
  anchor.setProvider(provider);
}
