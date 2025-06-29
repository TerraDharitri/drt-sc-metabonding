use pair::safe_price_view::ProxyTrait as _;
use router::factory::ProxyTrait as _;

use crate::Timestamp;

dharitri_sc::imports!();

pub enum PairQueryResponse<M: ManagedTypeApi> {
    WrewaIntermediary {
        token_to_wrewa_pair: ManagedAddress<M>,
        wrewa_to_usdc_pair: ManagedAddress<M>,
    },
    TokenToUsdc(ManagedAddress<M>),
}

#[dharitri_sc::module]
pub trait PriceQueryModule {
    fn get_usdc_value(
        &self,
        token_id: TokenIdentifier,
        amount: BigUint,
        price_timestamp: Timestamp,
    ) -> BigUint {
        let pair_query_response = self.get_pair_to_query(token_id.clone());
        match pair_query_response {
            PairQueryResponse::WrewaIntermediary {
                token_to_wrewa_pair,
                wrewa_to_usdc_pair,
            } => {
                let wrewa_token_id = self.wrewa_token_id().get();
                let wrewa_price = self.call_get_safe_price(
                    token_to_wrewa_pair,
                    token_id,
                    amount,
                    price_timestamp,
                );

                self.call_get_safe_price(
                    wrewa_to_usdc_pair,
                    wrewa_token_id,
                    wrewa_price,
                    price_timestamp,
                )
            }
            PairQueryResponse::TokenToUsdc(pair_addr) => {
                self.call_get_safe_price(pair_addr, token_id, amount, price_timestamp)
            }
        }
    }

    fn get_pair_to_query(&self, token_id: TokenIdentifier) -> PairQueryResponse<Self::Api> {
        let wrewa_token_id = self.wrewa_token_id().get();
        let usdc_token_id = self.usdc_token_id().get();
        let router_address = self.router_address().get();
        let token_to_wrewa_pair = self.call_get_pair(
            router_address.clone(),
            token_id.clone(),
            wrewa_token_id.clone(),
        );

        if !token_to_wrewa_pair.is_zero() {
            let wrewa_to_usdc_pair =
                self.call_get_pair(router_address, wrewa_token_id, usdc_token_id);
            require!(
                !wrewa_to_usdc_pair.is_zero(),
                "Invalid WREWA-USDC pair address from router"
            );

            return PairQueryResponse::WrewaIntermediary {
                token_to_wrewa_pair,
                wrewa_to_usdc_pair,
            };
        }

        let token_to_usdc_pair = self.call_get_pair(router_address, token_id, usdc_token_id);
        require!(
            !token_to_usdc_pair.is_zero(),
            "Invalid TOKEN-USDC pair address from router"
        );

        PairQueryResponse::TokenToUsdc(token_to_usdc_pair)
    }

    fn call_get_pair(
        &self,
        router_address: ManagedAddress,
        first_token_id: TokenIdentifier,
        second_token_id: TokenIdentifier,
    ) -> ManagedAddress {
        self.router_proxy(router_address)
            .get_pair(first_token_id, second_token_id)
            .execute_on_dest_context()
    }

    fn call_get_safe_price(
        &self,
        pair_address: ManagedAddress,
        token_id: TokenIdentifier,
        amount: BigUint,
        price_timestamp: Timestamp,
    ) -> BigUint {
        let input_payment = DcdtTokenPayment::new(token_id, 0, amount);
        let safe_price_pair = self.safe_price_pair().get();
        let price_payment: DcdtTokenPayment = self
            .pair_proxy(safe_price_pair)
            .get_safe_price_by_timestamp_offset(pair_address, price_timestamp, input_payment)
            .execute_on_dest_context();

        price_payment.amount
    }

    #[proxy]
    fn router_proxy(&self, sc_address: ManagedAddress) -> router::Proxy<Self::Api>;

    #[proxy]
    fn pair_proxy(&self, sc_address: ManagedAddress) -> pair::Proxy<Self::Api>;

    #[storage_mapper("routerAddress")]
    fn router_address(&self) -> SingleValueMapper<ManagedAddress>;

    #[storage_mapper("safePricePair")]
    fn safe_price_pair(&self) -> SingleValueMapper<ManagedAddress>;

    #[storage_mapper("usdcTokenId")]
    fn usdc_token_id(&self) -> SingleValueMapper<TokenIdentifier>;

    #[storage_mapper("wrewaTokenId")]
    fn wrewa_token_id(&self) -> SingleValueMapper<TokenIdentifier>;
}
