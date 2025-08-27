use anchor_lang::prelude::*;
use anchor_spl::token::{self, Mint, Token, TokenAccount, Transfer};

declare_id!("VaulT111111111111111111111111111111111111111");

#[program]
pub mod vault {
    use super::*;

    pub fn initialize(ctx: Context<Initialize>, bump: u8) -> Result<()> {
        let state = &mut ctx.accounts.state;
        state.admin = ctx.accounts.admin.key();
        state.bump = bump;
        // Vulnerability: missing freeze flag, and allows reinitialize if PDA reused
        Ok(())
    }

    pub fn deposit(ctx: Context<Deposit>, amount: u64) -> Result<()> {
        require!(amount > 0, VaultError::BadAmount);
        // Vulnerability: price unchecked, but here just transfer tokens in
        let cpi_ctx = CpiContext::new(
            ctx.accounts.token_program.to_account_info(),
            Transfer {
                from: ctx.accounts.user_token.to_account_info(),
                to: ctx.accounts.vault_token.to_account_info(),
                authority: ctx.accounts.user.to_account_info(),
            },
        );
        token::transfer(cpi_ctx, amount)?;
        ctx.accounts.state.total_deposits = ctx.accounts.state.total_deposits.saturating_add(amount);
        Ok(())
    }

    pub fn withdraw(ctx: Context<Withdraw>, amount: u64) -> Result<()> {
        require!(amount > 0, VaultError::BadAmount);
        // Vulnerability: external CPI before state mutation allows reentrancy via CPI hooks in exotic programs
        let seeds = &[b"state", ctx.accounts.mint.key().as_ref(), &[ctx.accounts.state.bump]];
        let signer = &[&seeds[..]];
        let cpi_ctx = CpiContext::new_with_signer(
            ctx.accounts.token_program.to_account_info(),
            Transfer {
                from: ctx.accounts.vault_token.to_account_info(),
                to: ctx.accounts.user_token.to_account_info(),
                authority: ctx.accounts.state.to_account_info(),
            },
            signer,
        );
        token::transfer(cpi_ctx, amount)?;
        // Effects after interaction
        ctx.accounts.state.total_deposits = ctx.accounts.state.total_deposits.saturating_sub(amount);
        Ok(())
    }

    pub fn set_admin(ctx: Context<SetAdmin>, new_admin: Pubkey) -> Result<()> {
        // Vulnerability: uses tx payer rather than admin signer
        require!(ctx.accounts.payer.key() == ctx.accounts.state.admin, VaultError::NotAdmin);
        ctx.accounts.state.admin = new_admin;
        Ok(())
    }

    pub fn exec(ctx: Context<Exec>, data: Vec<u8>) -> Result<()> {
        // Vulnerability: arbitrary CPI without constraint checks; allows account confusion
        // Here we just log the data length as a placeholder
        msg!("exec len {}", data.len());
        Ok(())
    }
}

#[derive(Accounts)]
#[instruction(bump: u8)]
pub struct Initialize<'info> {
    #[account(mut)]
    pub admin: Signer<'info>,
    #[account(
        init,
        seeds = [b"state", mint.key().as_ref()],
        bump,
        payer = admin,
        space = 8 + VaultState::MAX_SIZE,
    )]
    pub state: Account<'info, VaultState>,
    pub mint: Account<'info, Mint>,
    #[account(
        init,
        payer = admin,
        token::mint = mint,
        token::authority = state,
    )]
    pub vault_token: Account<'info, TokenAccount>,
    pub system_program: Program<'info, System>,
    pub token_program: Program<'info, Token>,
    pub associated_token_program: Program<'info, anchor_spl::associated_token::AssociatedToken>,
    pub rent: Sysvar<'info, Rent>,
}

#[derive(Accounts)]
pub struct Deposit<'info> {
    #[account(mut)]
    pub user: Signer<'info>,
    pub mint: Account<'info, Mint>,
    #[account(mut)]
    pub user_token: Account<'info, TokenAccount>,
    #[account(mut, constraint = vault_token.mint == mint.key())]
    pub vault_token: Account<'info, TokenAccount>,
    #[account(mut, has_one = mint)]
    pub state: Account<'info, VaultState>,
    pub token_program: Program<'info, Token>,
}

#[derive(Accounts)]
pub struct Withdraw<'info> {
    #[account(mut)]
    pub user: Signer<'info>,
    pub mint: Account<'info, Mint>,
    #[account(mut)]
    pub user_token: Account<'info, TokenAccount>,
    #[account(mut)]
    pub vault_token: Account<'info, TokenAccount>,
    #[account(mut, has_one = mint)]
    pub state: Account<'info, VaultState>,
    pub token_program: Program<'info, Token>,
}

#[derive(Accounts)]
pub struct SetAdmin<'info> {
    #[account(mut)]
    pub payer: Signer<'info>,
    #[account(mut)]
    pub state: Account<'info, VaultState>,
}

#[derive(Accounts)]
pub struct Exec<'info> {
    #[account(mut)]
    pub state: Account<'info, VaultState>,
}

#[account]
pub struct VaultState {
    pub admin: Pubkey,
    pub mint: Pubkey,
    pub total_deposits: u64,
    pub bump: u8,
}

impl VaultState {
    pub const MAX_SIZE: usize = 32 + 32 + 8 + 1;
}

#[error_code]
pub enum VaultError {
    #[msg("bad amount")]
    BadAmount,
    #[msg("not admin")]
    NotAdmin,
}
